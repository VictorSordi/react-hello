FROM nginx:stable-alpine

# Definir o fuso horário para São Paulo
ENV TZ=America/Sao_Paulo
RUN apk add --no-cache tzdata && \
    cp /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    apk del tzdata

# support running as arbitrary user which belogs to the root group
RUN chmod g+rwx /var/cache/nginx /var/run /var/log/nginx

EXPOSE 4040

RUN rm /etc/nginx/conf.d/default.conf && rm /etc/nginx/nginx.conf

# Copy the adjusted configuration files
COPY default.conf /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/nginx.conf

# users are not allowed to listen on priviliged ports
RUN sed -i.bak 's/listen\(.*\)80;/listen 4040;/' /etc/nginx/conf.d/default.conf

# comment user directive as master process is run as user in OpenShift anyhow
RUN sed -i.bak 's/^user/#user/' /etc/nginx/nginx.conf

COPY /dist /usr/share/nginx/html

# Start Nginx when the container starts
CMD ["nginx", "-g", "daemon off;"]

