# DNS Infrastructure Documentation

## Overview

The DNS infrastructure uses an anycast Virtual IP (VIP) setup with three redundant DNS nodes (dns1, dns2, dns3) providing high availability DNS services to the home network. All nodes advertise the same VIP address (`172.53.53.53`) via BGP, and clients automatically connect to the nearest/healthiest node.

## Architecture

```
Client Query (172.53.53.53)
    ↓
DNSdist (Load Balancer & Router)
    ↓
    ├─→ Local Bind (cbannister.casa, unifi, reverse DNS)
    ├─→ K8s Bind (cbannister.xyz, rociobolanos.com)
    ├─→ Local Blocky (Ad-blocking)
    └─→ Cloudflare DNS over TLS (Explicitly unfiltered networks)
```

## Components

### 1. Virtual IP (VIP)
- **IPv4**: `172.53.53.53/32`
- **IPv6 (local only)**: `fd74:f571:d3bd:53::53/128`
- Configured on dummy interface `dnsvip` on all three nodes
- The IPv4 VIP is advertised via BIRD/BGP when the node is healthy; the IPv6 VIP is not advertised.

### 2. DNS Nodes
- **dns1**: `10.254.53.0/31` (Brocade peer: `10.254.53.1`)
- **dns2**: `10.254.53.2/31` (Brocade peer: `10.254.53.3`)
- **dns3**: `10.254.53.4/31` (Brocade peer: `10.254.53.5`)
- Each DNS NIC uses its own `/31` point-to-point link carved from `10.254.53.0/24` for direct eBGP peering.

### 3. DNSdist (Frontend Load Balancer)
- Listens on VIP address (`172.53.53.53:53`)
- Health check listener: `127.0.0.1:5380` (for node health monitoring)
- Routes queries based on source IP and domain patterns
- Provides caching, metrics (Prometheus on port 5383)

**Backend Pools:**
- **bind**: Local Bind server (`127.0.53.10:53`)
- **k8s**: Kubernetes Bind server (`10.45.0.55:53`)
- **blocky**: Local Blocky ad-blocker (`127.0.53.20:53`)
- **cloudflare**: Cloudflare DNS over TLS (`1.1.1.1:853`, `1.0.0.1:853`)

**Backend Health Checks:**
DNSdist performs "lazy" health checks on backends:
- Monitors real query traffic as health probes
- Only does synthetic checks if no traffic for 30+ seconds
- Each backend has individual health check settings
- Blocky is checked with a deterministic local denylist entry, independently of Internet connectivity

**Routing Rules** (processed in order):
1. Special blocks (resolver.arpa, icloud masks) → NXDOMAIN
2. Domain-based routing:
   - `unifi`, `cbannister.casa` → Bind
   - `cbannister.xyz`, `rociobolanos.com` → K8s
   - Reverse DNS zones → Bind
3. Source IP routing:
   - Trusted/WireGuard networks → Blocky; return SERVFAIL if the Blocky pool is unavailable
   - Guest/IoT networks → Cloudflare
   - LAN/Servers/K8s overlay networks → Cloudflare
   - Default → Cloudflare

### 4. BIRD (BGP Routing)
- Manages dynamic routing advertisement of VIP
- The health check controls the `dnsvip_direct` IPv4 route.
- The IPv4 VIP is exported through BGP; IPv6 is not advertised.
- BGP uses local AS `65110` and peers with the directly connected upstream gateway in AS `65001`.
- When enabled: the direct VIP route becomes available to BGP for export.
- When disabled: BGP withdraws the VIP announcement.
- Provides automatic failover between nodes
- Each node uses a dedicated point-to-point link toward the Brocade ICX7250.

#### Brocade ICX7250 configuration

Each DNS VM connects to its own `/31` VLAN on the Brocade. FastIron 9 automatically associates a VE interface with the VLAN (no explicit `router-interface ve` command needed) once the `interface ve <id>` stanza exists.

Example for `dns1` (repeat for `dns2`/`dns3` with the appropriate VLAN ID, switch port, and `/31` addresses):

```text
conf t
!
vlan 3101 name DNS1-PTP
 tagged ethernet 1/2/6          ! Port facing the dns1 Proxmox NIC
 exit
!
interface ve 3101
 ip address 10.254.53.1 255.255.255.254
 exit
!
```

Key points:
- Use one VLAN/VE per DNS node so each link is isolated.
- Set the Proxmox port to **untagged** in that VLAN; other VLANs continue to be trunked on different switch ports.
- In the upstream BGP configuration (local AS `65001`), configure an eBGP neighbor for each DNS node using remote AS `65110`; verify that the switch learns `172.53.53.53/32` from all healthy nodes.

### 5. Backend Services

**Bind (Local Authoritative DNS)**
- Listens on: `127.0.53.10:53`
- Hosts zones:
  - `cbannister.casa` (home domain)
  - `unifi` (network management)
  - Multiple reverse DNS zones

**Blocky (Ad-Blocking DNS)**
- Listens on: `127.0.53.20:53`
- Uses multiple DNS-over-TLS upstream providers
- Blocklists: ads, fake news, gambling
- Web UI on port 4000

## Health Check System

### Purpose
The VIP health check is designed to detect **node-level failures** only:
- ✅ dnsdist service down/crashed
- ✅ dnsdist misconfigured and can't route
- ✅ Critical local services (Bind or Blocky) not functioning
- ✅ Blocky's filtering engine not enforcing its local denylist
- ✅ Node isolated from network

The health check should **NOT** withdraw VIP for:
- ❌ Internet outages (local DNS should continue working)
- ❌ External resolver failures while local filtering still works
- ❌ Cloudflare connectivity issues

### Implementation
**File**: `roles/dnsVip/dns-ha.nix`

**Health Check Queries**:
- `gateway.cbannister.casa` through dnsdist must return exactly `10.1.0.1`, validating dnsdist → Bind → local zone.
- `blocky-healthcheck.invalid` directly through Blocky must return exactly `0.0.0.0`, validating the local filtering engine.
- The Blocky test name is a deterministic local denylist entry and does not depend on a downloaded list or Internet resolution.

**Configuration**:
- Check interval: 5 seconds
- Failure threshold: 3 consecutive failures
- Success threshold: 2 consecutive successes
- DNS timeout: 2 seconds
- Query port: 5380 (localhost health check listener)

**State Machine**:
```
Health Check PASSES:
├─ If not advertising: increment success_count
│  └─ If success_count >= 2: Enable BIRD direct VIP routes
└─ If advertising: Reset success_count

Health Check FAILS:
├─ If advertising: increment failure_count
│  └─ If failure_count >= 3: Disable BIRD direct VIP routes
└─ If not advertising: Reset failure_count
```

**Failover Time**: ~15 seconds (3 failures × 5 second interval)
**Recovery Time**: ~10 seconds (2 successes × 5 second interval)

### Design Decision: Why Local Queries?

**Previous Implementation** (❌ PROBLEMATIC):
- Queried `google.com`
- When internet went down → query failed
- After 3 failures → VIP withdrawn
- **Result**: Entire DNS infrastructure down, even though local DNS should work

**Current Implementation** (✅ CORRECT):
- Validates both the dnsdist → Bind path and Blocky's local filtering path
- Verifies exact expected answers rather than only checking `dig`'s exit status
- Uses no external DNS dependency
- VIP stays up during internet outages
- Withdraws the node's VIP advertisement if either critical local path fails

**Why This Approach**:
1. **Separation of Concerns**: Health checking ≠ monitoring
   - Backend health monitoring is handled by dnsdist's built-in checks
   - Internet connectivity monitoring should be separate (Prometheus/alerting)
   - VIP health checks validate only deterministic local service behavior

2. **Simplicity Over Sophistication**:
   - Two exact local answers are robust and predictable
   - No complex internet detection logic needed
   - Easier to debug and understand

3. **Correct Failure Modes**:
   - Internet down → Local DNS continues working ✅
   - dnsdist down → VIP withdrawn ✅
   - Bind down → VIP withdrawn ✅
   - Blocky filtering down → VIP withdrawn ✅
   - External resolvers down but Blocky filtering works → VIP stays up ✅

4. **Routing Behavior**:
   - DNSdist processes rules in order
   - Domain rules match before source IP rules
   - Query for `gateway.cbannister.casa` from `127.0.0.1` matches domain rule first
   - Routes to Bind pool (not Cloudflare), ensuring local DNS path is tested
   - Blocky is tested directly so its result cannot be masked by dnsdist fallback routing

## File Structure

```
roles/dnsVip/
├── default.nix                      # Main VIP orchestration
├── dns-ha.nix                       # Health check daemon (CRITICAL)
├── dnsdist.nix                      # DNSdist service config
├── bind.nix                         # Bind service config
├── blocky.nix                       # Blocky service config
├── bird.nix                         # BIRD routing config
└── files/
    ├── dnsdist/
    │   └── config.lua               # DNSdist routing rules & backend health
    └── bind/zones/
        ├── db.cbannister.casa       # Home domain zone
        ├── db.unifi                 # Unifi zone
        └── db.*.in-addr.arpa        # Reverse DNS zones

systems/
├── dns1/default.nix                 # nodeIp: 10.254.53.0
├── dns2/default.nix                 # nodeIp: 10.254.53.2
└── dns3/default.nix                 # nodeIp: 10.254.53.4
```

Kubernetes authoritative zones are configured once in
`services.dnsVip.kubernetesDomains` in `roles/dnsVip/default.nix`. DNSdist
routes every listed zone to the shared Kubernetes backend and uses the first
zone for its backend health check.

## Monitoring

### Metrics
- **DNSdist**: Prometheus metrics on `http://<node-ip>:5383/metrics`
- **Blocky**: Prometheus metrics on `http://<node-ip>:4000/metrics`
- **Vector**: Ships structured journal events to VictoriaLogs and exports internal metrics on `http://<node-ip>:9598/metrics`
- **Health Check**: Logs to systemd journal (`journalctl -u dns-healthcheck`)

### Health Check Logs
```bash
# View health check status
journalctl -u dns-healthcheck -f

# Check BIRD protocol status
birdc show protocols dnsvip_direct
birdc show protocols dnsvip_bgp
birdc show route export dnsvip_bgp

# Check DNSdist stats
curl -s http://localhost:5383/metrics

# Test health check endpoint directly
dig @127.0.0.1 -p 5380 gateway.cbannister.casa +short
dig @127.0.53.20 blocky-healthcheck.invalid +short
```

## Troubleshooting

### VIP Not Advertising
1. Check health check service: `systemctl status dns-healthcheck`
2. Check health check logs: `journalctl -u dns-healthcheck -n 50`
3. Manually test both DNS queries: `dig @127.0.0.1 -p 5380 gateway.cbannister.casa +short` and `dig @127.0.53.20 blocky-healthcheck.invalid +short`
4. Check BIRD status: `birdc show protocols`
5. Verify dnsdist is running: `systemctl status dnsdist`
6. Verify Bind is running: `systemctl status bind`

### DNS Queries Failing
1. Check if VIP is up: `ip addr show dnsvip`
2. Check dnsdist is listening: `ss -tlnp | grep 5380`
3. Check backend health: Review dnsdist logs
4. Test each backend directly:
   ```bash
   dig @127.0.53.10 gateway.cbannister.casa  # Bind
   dig @127.0.53.20 google.com               # Blocky
   dig @10.45.0.55 cbannister.xyz            # K8s
   ```

### Internet Down But DNS Should Work
**Expected behavior**: VIP should stay up, local queries should work
- Local domains (*.cbannister.casa, unifi) → Should resolve ✅
- External domains → May fail if all backends down ⚠️
- Health check → Should pass (queries only deterministic local paths) ✅

If VIP goes down when internet fails, health check may be misconfigured.

## Philosophy for Critical Infrastructure

When working with DNS or other critical network infrastructure:

1. **Favor Simplicity**: Complex logic = more failure modes
2. **Separate Concerns**: Health checks ≠ monitoring ≠ alerting
3. **Think About Failure Modes**: What should actually bring down a service?
4. **Avoid Cascading Failures**: One system's failure shouldn't break everything
5. **Test Edge Cases**: What happens when internet is down? When one backend fails?
6. **Monitoring Layers**:
   - Health checks → Withdraw VIP if node broken
   - Backend health checks → Route around failed backends
   - Prometheus/Alerts → Notify about degraded state

## Future Considerations

### Potential Improvements
- **Prometheus alerting**: Alert when backends unhealthy but VIP still up
- **Rate limiting**: Add rate limiting rules to dnsdist
- **DNSSEC**: Consider DNSSEC validation
- **Logging**: Enhanced query logging for specific networks

### Not Recommended
- ❌ Making health check query external domains (breaks during internet outages)
- ❌ Complex internet detection logic (adds fragility)
- ❌ Mixing external-connectivity status into the local VIP-advertisement decision

## Change Log

### 2026-09-29: Filtering Reliability and Observability
**Problem**: Blocky upstream timeouts marked the filtering backend down, and trusted clients then failed open to unfiltered Cloudflare. Several list sources were broken or redundant, filtered and unfiltered pools shared one packet cache, and Vector was not active on the DNS nodes.

**Solution**:
- Added a deterministic local Blocky health-check domain and exact-answer VIP checks.
- Changed protected clients to fail closed when Blocky is unavailable.
- Separated filtered and unfiltered dnsdist caches.
- Repaired the Yoyo source, made local list entries explicit files, and removed empty/redundant sources.
- Activated Vector on all DNS nodes.

### 2025-10-22: Health Check Fix
**Problem**: Health check queried `google.com`, causing VIP to withdraw during internet outages even though local DNS should continue working.

**Solution**: Changed health check to query `gateway.cbannister.casa` (local Bind zone).

**Impact**:
- VIP now stays up during internet outages ✅
- Local DNS resolution continues working ✅
- Health check still detects actual node failures ✅

**Modified File**: `roles/dnsVip/dns-ha.nix` (line 36)
