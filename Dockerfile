FROM debian

WORKDIR /dashboard

RUN apt-get update &&\
    apt-get -y install openssh-server wget iproute2 vim git cron unzip supervisor nginx sqlite3 curl &&\
    git config --global core.bigFileThreshold 1k &&\
    git config --global core.compression 0 &&\
    git config --global advice.detachedHead false &&\
    git config --global pack.threads 1 &&\
    git config --global pack.windowMemory 50m &&\
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/* &&\
    echo "#!/usr/bin/env bash\n\n\
bash <(wget -qO- https://raw.githubusercontent.com/dsadsadsss/Docker-for-Nezha-Argo-server-v1.x/main/init.sh)" > entrypoint.sh &&\
    chmod +x entrypoint.sh

# supervisor 依赖 hard link 来创建 /var/run/supervisor.sock。CF(Guardian) 容器的根文件系统是 9p，
# 9p 不支持对 UNIX socket 文件做 hard link（os.link 返回 EOPNOTSUPP=95），supervisord 会把它误判成
# "残留 socket" 而无限重试（每 0.3s 刷一行 Unlinking stale socket），永远走不到启动子程序那一步，
# 结果 caddy 起不来、端口 80 不监听、CF 的 port 健康检查必然超时。把 socket 挪到 tmpfs 即可绕开。
RUN sed -i 's#^file=/var/run/supervisor\.sock#file=/dev/shm/supervisor.sock#' /etc/supervisor/supervisord.conf &&\
    sed -i 's#^serverurl=unix:///var/run/supervisor\.sock#serverurl=unix:///dev/shm/supervisor.sock#' /etc/supervisor/supervisord.conf
ENV PORT=80
EXPOSE $PORT

# 启动容器
ENTRYPOINT ["/dashboard/entrypoint.sh"]



