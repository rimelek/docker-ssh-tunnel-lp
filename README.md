## Description

This is an SSH tunnel to forward port from a container to a local port of a machine in a private network.
It works only with SSH Keys, so you need to mount your keys into the tunnel container.

**Docker Compose Example**

    version: '2'
    
    services:
      webapp:
        restart: always
        image: my-webapp-image
        ports:
          - 80:80
      tunnel:
        image: rimelek/ssh-tunnel-lp
        network_mode: service:webapp
        volumes:
          - "${HOME}/.ssh:/root/.ssh"
        depends_on:
          - webapp
        environment:
          TUNNEL_HOST: "mytunneluser@my.tunnel.host:12345"
          TUNNEL_REMOTES: |
            mysql.intranet.lan:3306
            nonrootuser@apiserver.intranet.lan:443
            nonrootuser@dockerhost.intranet.lan:2375:2222
            
Each line of an ssh tunnel has the following format:

    [nonrootuser@]hostname:serviceport[:sshport]

