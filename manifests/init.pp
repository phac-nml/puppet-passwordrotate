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

  # specify VAULT_ADDR environment variable
  file_line { 'vault_addr_env_var':
    ensure => present,
    line   => "export VAULT_ADDR=${vault_addr}",
    path   => '/etc/environment',
  }

  # specify VAULT_TOKEN environment variable
  file_line { 'vault_token_env_var':
    ensure => present,
    line   => "export VAULT_TOKEN=${vault_token}",
    path   => '/etc/environment',
  }

  # add rotate_linux_password script to path
  # only root needs to run it
  file { '/usr/local/bin/rotate_linux_password':
    ensure => 'file',
    path   => '/usr/local/sbin/rotate_linux_password',
    mode   => '0700',
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
      default: {}
    }
  }
}
