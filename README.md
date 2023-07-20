# passwordrotate

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with passwordrotate](#setup)
    * [What passwordrotate affects](#what-passwordrotate-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with passwordrotate](#beginning-with-passwordrotate)
1. [Usage - Configuration options and additional functionality](#usage)

## Description

This module enables LAPS-like password rotation on Linux using Hashicorp Vault.

## Setup

### What passwordrotate affects

* Modifies `/etc/environment` to permanently add environment variable for `VAULT_ADDR` and `VAULT_TOKEN`.
* Adds new file to `/etc/cron.d/` for every user with rotating passwords
* Adds `rotate_linux_password` script to `/usr/local/sbin`
* Automatically installs `jq` if it is not already present

### Setup Requirements

A vault cluster must already be set up with the
[vault-secrets-gen](https://github.com/sethvargo/vault-secrets-gen) plugin enabled.
It must also have the `rotate-linux` policy from
[this](https://github.com/scarolan/painless-password-rotation) repository and a token
created using that policy to use on this machine.

### Beginning with passwordrotate

Generate a token for this machine that lasts longer than the desired password
rotation time on your vault cluster and set
the `passwordrotate::vault_token` variable in your hieradata.
Set `passwordrotate::vault_addr` to be the url of your vault cluster.
After that, simply run puppet to have password rotation enabled.

## Usage

Simply declare the vault token and address and any users if applicable.

### Examples:

```pp
class { 'passwordrotate':
    vault_token => asfldkj0q2349galkgj0934ngg09324qngqgklj,
    vault_addr  => https://192.168.56.10:8200,
}
```

```pp
class { 'passwordrotate':
    vault_token => asfldkj0q2349galkgj0934ngg09324qngqgklj,
    vault_addr  => https://192.168.56.10:8200,
    vault_users => [
        {
            user      => 'root',
            frequency => 'hourly',
        },
        {
            user      => 'otherUser',
            frequency => 'monthly'
        }
    ],
}
```

## Reference

### `passwordrotate`

#### Parameters

##### `vault_addr`

Address of the vault cluster. Valid options: 'string'.

##### `vault_token`

Token generated by and allowing access to the vault cluster. Valid options: 'string'.

##### `vault_users`

Array of users who should have their passwords rotated and the frequency it should be done.
For each user set `user` to their username and `frequency` to one of 'hourly', 'daily', 'weekly',
or 'monthly'.

Default:
```json
[
    {
        "user": "root",
        "frequency": "daily",
    },
]
```
