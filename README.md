Pushover to XMPP
----------------

---

## ARCHIVED

I migrated from Pushover to [Overpush](https://github.com/mrusme/overpush),
hence this project is no longer maintained.

---

This repository contains a <500 LOC [Pushover](https://pushover.net) to
[XMPP](https://xmpp.org) *bridge* that uses Pushover's [Open Client
API](https://pushover.net/api/client) to get notified about new Pushover
notifications and forwards them to an XMPP account, using
[go-xmpp](https://github.com/mattn/go-xmpp).

## Background

The reason for building this was my switch over from
[/e/OS](https://e.foundation/e-os/) to [GrapheneOS](https://grapheneos.org)
(read more about that [here](https://xn--gckvb8fzb.com/phone/)) and
hence the lack of a Pushover client that would function [without
GSF/GCM/FCM](https://grapheneos.org/faq#notifications). Unfortunately the 
[official Pushover 
Android](https://play.google.com/store/apps/details?id=net.superblock.pushover) 
app depends on the Google Service Framework and implements no 
websocket-driven fallback on its own. Hence, on Graphene it refuses to start.

Since I was already using
[Conversations](https://f-droid.org/en/packages/eu.siacs.conversations/), an
XMPP client that works without GSF/GCM/FCM, the easiest solution for continuing
to retrieve Pushover notifications on Android was to simply forward them to my
XMPP server.

This *quick and (very) dirty* Go service does exactly that.


## Build

```sh
go build .
```

The binary is named `pushover-to-xmpp`.


## Configure

For the sake of simplicity I added a `login.sh` script, which basically does
what the [Pushover API documentation](https://pushover.net/api/client) tells
under *User Login* and *Device Registration* in an automated fashion. The script
depends on `curl` and `jq` to be available. You can run it as following:

```sh
./login.sh <pushover e-mail> <pushover password> <two factor code>
```

The script does not implement login without 2FA, because you **should** use 2FA.

The script will output a Device ID and a secret. Keep those.

If you don't trust the script, just perform the `curl` requests mentioned in the
documentation yourself. You don't have to do this before every start, it's only
required once or in case you delete the device or the secret is invalidated.


## Run

The bridge requires a dedicated XMPP account, either on your own server or a
different one that is permitted to S2S with yours. You also have to make sure
upfront that the account is able to communicate with the target account. 
`pushover-to-xmpp` won't send or accept presence requests on its own, so make
sure to pre-configure the account the way you'd need it.

You can run the bridge by exporting its required ENV variables and running the
`pushover-to-xmpp` binary:

```sh
export PTX_DEVICE_ID='<pushover device id>' \
       PTX_SECRET='<pushover secret>' \
       PTX_XMPP_SERVER='your-xmpp.org:5222' \
       PTX_XMPP_USER='pushover@your-xmpp.org' \ 
       PTX_XMPP_PASSWORD='password' \
       PTX_XMPP_TLS=true \
       PTX_XMPP_TARGET='user@your-xmpp.org'
```

The `PTX_XMPP_TARGET` is the target user that the bridge should forward Pushover
notifications to.

It's best to run the bridge via e.g. `supervisord`, in order to make
sure it keeps running and, in case it won't, you're being notified about that.

For that purpose create a dedicated user (e.g. `ptx`), download and unpack [one 
of the binary releases](https://github.com/mrusme/pushover-to-xmpp/releases) 
and add something along these lines to your `/etc/supervisord.conf` (or
`/usr/local/etc/supervisord.conf`):

```conf
[program:pushover-to-xmpp]
command=/home/ptx/pushover-to-xmpp
numprocs=1
autostart=true
startsecs=5
startretries=3
autorestart=true
user=ptx
directory=/home/ptx
environment=PTX_DEVICE_ID="...",PTX_SECRET="...",PTX_XMPP_SERVER="...",...
```

(`environment` should contain the same ENVs as listed above, separated by comma,
with each key's value in quotes)

Whenever the bridge starts, the target user will receive a *"Hello World"*
message to know that the bridge was just (re-?)started.

