# n8n Docker 이미지 for Render
FROM n8nio/n8n:latest

# 한국 시간대 설정
ENV TZ=Asia/Seoul

# 포트 노출
EXPOSE 5678

# 헬스체크 (Render 슬립 방지용)
HEALTHCHECK --interval=5m --timeout=3s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:5678/healthcheck || exit 1
