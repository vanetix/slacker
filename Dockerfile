FROM elixir:1.6-alpine as build

WORKDIR /var/www/

COPY . .

RUN apk add -U nodejs git
RUN npm install --prefix apps/slacker_frontend/assets && \
    mix do local.hex --force, local.rebar --force, deps.get --only prod && \
    npm run build --prefix apps/slacker_frontend/assets && \
    MIX_ENV=prod mix do phx.digest, release


FROM alpine:3.7

ENV PORT 8080
ENV VERSION 0.0.1
WORKDIR /var/www/

COPY --from=build /var/www/_build/prod/rel/slacker/releases/$VERSION/slacker.tar.gz ./app.tar.gz

RUN apk add -U bash openssl && \
    tar -xzf app.tar.gz && \
    rm -f app.tar.gz

EXPOSE $PORT

CMD ["./bin/slacker", "foreground"]

