-- udp/tcp dns listening
-- Note: NixOS service configures primary listening address (172.53.53.53:53)

-- Health check listener on localhost - used by healthcheck service to verify dnsdist
-- functionality without depending on VIP state (port 5380 to avoid mDNS conflict on 5353)
addLocal("127.0.0.1:5380", {})

-- disable security status polling via DNS
setSecurityPollSuffix("")
setVerboseHealthChecks(true)

-- Restrict to home networks only
addACL('fd74:f571:d3bd::/48')
addACL('10.0.0.0/8')
addACL('192.168.0.0/16')
addACL('127.0.0.0/8')
addACL('172.20.0.0/16')

-- enable prometheus
-- webserver("0.0.0.0:8083")
-- setWebserverConfig({
--     statsRequireAuthentication = false,
--     acl = "10.0.0.0/8, 127.0.0.0/8"
-- })
setAPIWritable(false)

-- Local Bind
newServer({
    address = "127.0.0.1:20053",
    pool = "bind",
    reconnectOnUp = true,
    healthCheckMode = "lazy",
    checkInterval = 1,
    lazyHealthCheckFailedInterval = 30,
    rise = 2,
    maxCheckFailures = 3,
    checkType = 'SOA',
    checkName = 'cbannister.casa.',
    mustResolve = true,
    lazyHealthCheckThreshold = 30,
    lazyHealthCheckSampleSize = 100,
    lazyHealthCheckMinSampleCount = 10,
    lazyHealthCheckMode = 'TimeoutOnly',
    useClientSubnet = true
})

-- K8s Bind
newServer({
    address = "10.45.0.55",
    pool = "k8s",
    reconnectOnUp = true,
    healthCheckMode = "lazy",
    checkInterval = 1,
    lazyHealthCheckFailedInterval = 30,
    rise = 2,
    maxCheckFailures = 3,
    lazyHealthCheckThreshold = 30,
    lazyHealthCheckSampleSize = 100,
    lazyHealthCheckMinSampleCount = 10,
    lazyHealthCheckMode = 'TimeoutOnly',
    useClientSubnet = true
})

-- Local Blocky
newServer({
    address = "127.0.0.1:10053",
    pool = "blocky",
    reconnectOnUp = true,
    healthCheckMode = "lazy",
    checkInterval = 30,
    maxCheckFailures = 3,
    lazyHealthCheckFailedInterval = 30,
    rise = 2,
    lazyHealthCheckThreshold = 30,
    lazyHealthCheckSampleSize = 100,
    lazyHealthCheckMinSampleCount = 10,
    lazyHealthCheckMode = 'TimeoutOnly',
    useClientSubnet = true
})
-- Blocky will be given requester IP
setECSSourcePrefixV4(32)

-- CloudFlare DNS over TLS
newServer({
    address = "1.1.1.1:853",
    tls = "openssl",
    reconnectOnUp = true,
    subjectName = "cloudflare-dns.com",
    validateCertificates = true,
    checkInterval = 10,
    checkTimeout = 2000,
    pool = "cloudflare"
})
newServer({
    address = "1.0.0.1:853",
    tls = "openssl",
    reconnectOnUp = true,
    subjectName = "cloudflare-dns.com",
    validateCertificates = true,
    checkInterval = 10,
    checkTimeout = 2000,
    pool = "cloudflare"
})

-- Enable caching
pc = newPacketCache(1000000, {
    maxTTL = 86400,
    minTTL = 0,
    temporaryFailureTTL = 60,
    staleTTL = 60,
    dontAge = false
})
-- getPool("blocky"):setCache(pc)
getPool("cloudflare"):setCache(pc)

-- addAction(AllRule(), LogAction("", false, false, true, false, false))
-- addResponseAction(AllRule(), LogResponseAction("", false, true, false, false))

addAction("192.168.2.0/24", PoolAction("blocky")) -- guest vlan

-- block responding to this so that downstream clients cant discover upstream resolvers
-- that bypass blocky.
addAction(QNameSuffixRule('resolver.arpa'), ERCodeAction(DNSRCode.NXDOMAIN))
addAction(QNameSuffixRule('mask.icloud.com'), ERCodeAction(DNSRCode.NXDOMAIN))
addAction(QNameSuffixRule('mask-h2.icloud.com'), ERCodeAction(DNSRCode.NXDOMAIN))

-- send anything from k8s to cloudflare

addAction('plex.cbannister.xyz', SpoofAction('10.45.0.20'))

-- this will send this domain to the bind server
addAction('unifi', PoolAction('bind'))
addAction('cbannister.xyz', PoolAction('k8s'))
addAction('cbannister.casa', PoolAction('bind'))

-- Reverse DNS zones to bind
addAction({
    '0.1.10.in-addr.arpa',    -- LAN reverse
    '1.1.10.in-addr.arpa',    -- SERVERS reverse
    '2.1.10.in-addr.arpa',    -- TRUSTED reverse
    '3.1.10.in-addr.arpa',    -- IOT reverse
    '8.1.10.in-addr.arpa',    -- K8S reverse
    '2.168.192.in-addr.arpa'  -- GUEST reverse
}, PoolAction('bind'))

addAction("10.1.3.1/24", PoolAction("blocky"))     -- iot
addAction("10.1.0.0/24", PoolAction("cloudflare")) -- lan
addAction("10.1.8.0/24", PoolAction("cloudflare"))
addAction({"10.1.1.0/24", "10.254.1.0/24"},  PoolAction("cloudflare"))     -- servers
addAction({"10.1.2.0/24", "fd74:f571:d3bd:20::/64"}, PoolAction("blocky"))     -- trusted
addAction({"10.1.3.0/24", "fd74:f571:d3bd:40::/64"}, PoolAction("blocky"))     -- iot

addAction("10.0.11.0/24", PoolAction("blocky"))    -- wireguard
addAction({'10.42.0.0/16', '172.20.0.0/16'}, PoolAction('cloudflare'))

addAction('127.0.0.1', PoolAction('cloudflare'))

-- log queries from unknown subnets
addAction(AllRule(), LogAction('', true, false, true, false))

-- default pool for unmatched queries (including from VIP itself)
addAction(AllRule(), PoolAction("cloudflare"))
