FROM elixir:1.6-alpine

ENV PORT 8080
ENV VERSION 0.0.1

# Tell distillery to expand environment variables in vm.args
ENV REPLACE_OS_VARS true

WORKDIR /var/www/

COPY . .

RUN apk add -U nodejs git openssl bash
RUN npm install --prefix apps/slacker_frontend/assets && \
    mix do local.hex --force, local.rebar --force, deps.get --only prod && \
    npm run build --prefix apps/slacker_frontend/assets && \
    MIX_ENV=prod mix do phx.digest, release

EXPOSE $PORT

CMD ["_build/prod/rel/slacker/bin/slacker", "foreground"]
