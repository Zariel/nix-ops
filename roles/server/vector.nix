{ config, ... }:
let
  metricsAddresses = {
    dns-1 = "10.254.53.0";
    dns-2 = "10.254.53.2";
    dns-3 = "10.254.53.4";
    nix-builder = "10.1.1.155";
    matchbox = "10.1.1.20";
  };
  metricsAddress = metricsAddresses.${config.networking.hostName} or "127.0.0.1";
in
{
  services.vector = {
    enable = true;
    journaldAccess = true;

    settings = {
      data_dir = "/var/lib/vector";

      sources = {
        journal = {
          type = "journald";
          current_boot_only = true;
          since_now = true;
          exclude_units = [ "vector.service" ];
        };

        vector_internal_metrics.type = "internal_metrics";
      };

      transforms = {
        journal_normalize = {
          type = "remap";
          inputs = [ "journal" ];
          source = ''
            .source_stream = "nixos"

            if exists(._SYSTEMD_UNIT) && is_string(._SYSTEMD_UNIT) {
              .service = ._SYSTEMD_UNIT
            }

            if exists(.SYSLOG_IDENTIFIER) && is_string(.SYSLOG_IDENTIFIER) {
              .application = .SYSLOG_IDENTIFIER
            } else if exists(._COMM) && is_string(._COMM) {
              .application = ._COMM
            } else if exists(.service) {
              .application = replace!(.service, r'\.service$', "")
            }

            if exists(.PRIORITY) {
              priority, priority_err = to_int(.PRIORITY)
              if priority_err == null {
                .log_level = upcase(to_syslog_level(priority) ?? "unknown")
              }
            }

            if !exists(.msg) && exists(.message) {
              .msg = .message
            }

            if .service == "blocky.service" && exists(.message) && is_string(.message) {
              parsed, parse_err = parse_json(.message)
              if parse_err == null && is_object(parsed) {
                if exists(parsed.prefix) && is_string(parsed.prefix) {
                  .prefix = parsed.prefix
                }
                if exists(parsed.msg) && is_string(parsed.msg) {
                  .msg = parsed.msg
                }
                if exists(parsed.level) && is_string(parsed.level) {
                  .log_level = upcase!(parsed.level)
                }

                if exists(parsed.client_ip) && is_string(parsed.client_ip) {
                  .dns_client_ip = parsed.client_ip
                }
                if exists(parsed.client_names) && is_string(parsed.client_names) {
                  .dns_client_names = parsed.client_names
                }
                if exists(parsed.response_reason) && is_string(parsed.response_reason) {
                  .dns_response_reason = parsed.response_reason
                }
                if exists(parsed.response_type) && is_string(parsed.response_type) {
                  .dns_response_type = parsed.response_type
                }
                if exists(parsed.response_code) && is_string(parsed.response_code) {
                  .dns_response_code = parsed.response_code
                }
                if exists(parsed.question_name) && is_string(parsed.question_name) {
                  .dns_question_name = parsed.question_name
                }
                if exists(parsed.question_type) && is_string(parsed.question_type) {
                  .dns_question_type = parsed.question_type
                }
                if exists(parsed.duration_ms) && is_integer(parsed.duration_ms) {
                  .dns_duration_ms = parsed.duration_ms
                }
                if exists(parsed.instance) && is_string(parsed.instance) {
                  .dns_instance = parsed.instance
                }
              }
            }

            del(._SYSTEMD_INVOCATION_ID)
            del(._STREAM_ID)
            del(._SYSTEMD_CGROUP)
            del(._BOOT_ID)
            del(._MACHINE_ID)
            del(._CAP_EFFECTIVE)
            del(.__MONOTONIC_TIMESTAMP)
            del(.__REALTIME_TIMESTAMP)
            del(.source_type)
          '';
        };

        blocky_query_route = {
          type = "route";
          inputs = [ "journal_normalize" ];
          route.query = ''
            .service == "blocky.service" && .prefix == "queryLog" && .msg == "query resolved"
          '';
        };

        blocky_query_classify = {
          type = "remap";
          inputs = [ "blocky_query_route.query" ];
          source = ''
            response_type_valid = exists(.dns_response_type) && is_string(.dns_response_type)
            response_code_valid = exists(.dns_response_code) && is_string(.dns_response_code)

            .dns_parse_error = !response_type_valid || !response_code_valid

            response_type = if response_type_valid {
              upcase!(.dns_response_type)
            } else {
              ""
            }
            response_code = if response_code_valid {
              upcase!(.dns_response_code)
            } else {
              ""
            }

            if response_type_valid {
              .dns_response_type = response_type
            }
            if response_code_valid {
              .dns_response_code = response_code
            }

            ._dns_is_abnormal =
              includes(["BLOCKED", "REBIND", "BOGUS"], response_type) ||
              includes(["SERVFAIL", "REFUSED", "FORMERR", "NOTIMP"], response_code)
          '';
        };

        abnormal_blocky_query = {
          type = "filter";
          inputs = [ "blocky_query_classify" ];
          condition = ".dns_parse_error == true || ._dns_is_abnormal == true";
        };

        blocky_query_cleanup = {
          type = "remap";
          inputs = [ "abnormal_blocky_query" ];
          source = ''
            del(._dns_is_abnormal)
            if .dns_parse_error == false {
              del(.dns_parse_error)
            }
          '';
        };
      };

      sinks = {
        kubernetes_vector = {
          type = "vector";
          inputs = [
            "blocky_query_cleanup"
            "blocky_query_route._unmatched"
          ];
          address = "10.45.0.2:6004";
          version = "2";
          compression = "zstd";
          acknowledgements.enabled = true;
          buffer = {
            type = "disk";
            max_size = 536870912;
            when_full = "block";
          };
        };

        internal_metrics_exporter = {
          type = "prometheus_exporter";
          inputs = [ "vector_internal_metrics" ];
          address = "${metricsAddress}:9598";
        };
      };
    };
  };
}
