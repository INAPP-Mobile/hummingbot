# Pinned upstream release image (conda-based, ~1.4 GB). Do NOT use :latest.
FROM hummingbot/hummingbot:version-2.16.0

USER root

ENV HEADLESS_MODE=true
ENV SCRIPT_CONFIG=simple_pmm.yml
ENV PORT=8080

# Template runtime helpers live outside /home/hummingbot so a mounted volume
# can never shadow them.
COPY entrypoint.sh /opt/hb-template/entrypoint.sh
COPY healthcheck_server.py /opt/hb-template/healthcheck_server.py
COPY patch_strategy.py /opt/hb-template/patch_strategy.py
COPY init_password.py /opt/hb-template/init_password.py
COPY seed/simple_pmm.yml /opt/hb-template/seed/simple_pmm.yml
RUN chmod +x /opt/hb-template/entrypoint.sh

# Interactive shells (railway ssh) start in conda `base`, which lacks hummingbot
# deps — `hbot` then dies with ModuleNotFoundError (pandas). Auto-activate the
# hummingbot env for login (profile.d) and interactive (.bashrc) shells.
RUN echo "source /opt/conda/etc/profile.d/conda.sh && conda activate hummingbot" \
      > /etc/profile.d/hummingbot-env.sh \
 && echo "source /opt/conda/etc/profile.d/conda.sh && conda activate hummingbot" \
      >> /root/.bashrc

# HTTP health endpoint used by the Railway healthcheck.
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=180s --retries=5 \
  CMD python3 -c "import urllib.request,sys;sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8080/health',timeout=4).status==200 else 1)"

CMD ["/opt/hb-template/entrypoint.sh"]