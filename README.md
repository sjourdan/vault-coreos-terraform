

$ fleetctl list-machines

cat hello.service


[Unit]
Description=My Service
After=docker.service

[Service]
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker kill hello
ExecStartPre=-/usr/bin/docker rm hello
ExecStartPre=/usr/bin/docker pull busybox
ExecStart=/usr/bin/docker run --name hello busybox /bin/sh -c "while true; do echo Hello World; sleep 1; done"
ExecStop=/usr/bin/docker stop hello

fleetctl submit hello.service

fleetctl list-units
fleetctl list-unit-files

fleetctl cat hello.service

$ fleetctl load hello.service
Unit hello.service loaded on 6147c03d.../10.133.169.81

$ fleetctl list-unit-files
UNIT            HASH    DSTATE  STATE   TARGET
hello.service   0d1c468 loaded  loaded  6147c03d.../10.133.169.81

$ fleetctl start hello.service
Unit hello.service launched on 6147c03d.../10.133.169.81

fleetctl status vault.service

$ fleetctl journal -f vault.service
$ fleetctl journal -lines=100 -f vault@8200.service
-- Logs begin at Tue 2015-05-05 17:13:23 UTC, end at Tue 2015-05-05 17:19:14 UTC. --
$ fleetctl ssh vault@8200 cat /etc/environment

$ docker exec -t -i d0070bbe8c63 /bin/sh
