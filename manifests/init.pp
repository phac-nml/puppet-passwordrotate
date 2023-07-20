# @summary This class handles password rotation using vault. It defaults to rotating the root password daily
# @param vault_addr The url to the vault cluster
# @param vault_token A token created on the vault cluster using the rotate-linux policy
# @param vault_users A list of the users that should have rotating passwords and the frequency of that
class passwordrotate(
  String $vault_addr,
  String $vault_token,
  Array[Struct[{
    user  => String,
    frequency => String
  }]] $vault_users = [
    {
      user  => 'root',
      frequency => 'daily'
    }
  ]
){
  include cron

  # dependency of the rotate_linux_password script
  stdlib::ensure_packages(['jq'], {'ensure' => 'present'})

  file { '/root/vault_info':
    ensure  => present,
    path    => '/root/vault_info',
    mode    => '0400',
    content => "VAULT_ADDR=${vault_addr}
VAULT_TOKEN=${vault_token}
",
  }

  # add rotate_linux_password script to path
  # only root needs to run it
  file { '/usr/local/bin/rotate_linux_password':
    ensure => 'file',
    path   => '/usr/local/sbin/rotate_linux_password',
    mode   => '0500',
    source => 'puppet:///modules/passwordrotate/rotate_linux_password'
  }

  # schedule the rotate_linux_password script as a cron job
  # if the frequency is invalid, do nothing
  $vault_users.each |Struct[{
    user  => String,
    frequency => String
  }] $value| {
    $command = "rotate_linux_password ${value[user]}"
    $description = "Rotate ${value[user]} password in vault"
    $environment = [ 'MAILTO=root', 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"' ]
    case $value[frequency] {
      hourly: {
        cron::hourly { "rotate_${value[user]}_hourly":
          user        => root,
          command     => $command,
          environment => $environment,
          description => $description
        }
      }
      daily: {
        cron::daily { "rotate_${value[user]}_daily":
          user        => root,
          command     => $command,
          environment => $environment,
          description => $description
        }
      }
      weekly: {
        cron::weekly { "rotate_${value[user]}_weekly":
          user        => root,
          command     => $command,
          environment => $environment,
          description => $description
        }
      }
      monthly: {
        cron::monthly { "rotate_${value[user]}_monthly":
          user        => root,
          command     => $command,
          environment => $environment,
          description => $description
        }
      }
      default: {
        fail("${value[frequency]} please choose one of hourly, daily, weekly, or monthly.")
      }
    }
  }
}
