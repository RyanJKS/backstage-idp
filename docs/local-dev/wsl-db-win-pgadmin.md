# View WSL PostgreSQL databases in Windows pgAdmin

[Back to README](../../README.md)

This setup runs Backstage and PostgreSQL inside WSL, with pgAdmin on Windows.
Windows PostgreSQL and WSL PostgreSQL are separate servers. Register a separate
pgAdmin connection for WSL to see its `backstage_plugin_*` databases.

The commands below use PostgreSQL 14, cluster `main`, and default WSL NAT
networking. Check your version with `pg_lsclusters` and adjust paths if needed.

## 1. Confirm the databases exist in WSL

From the repository root, connect using the same environment as Backstage.
Keep this command on one line; a newline after `-U` splits the shell command.

```sh
yarn exec sh -c 'psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres -W'
```

Enter `POSTGRES_PASSWORD` from your local `.env.yarn` when prompted. Yarn loads
that file automatically; do not put the password in the command.

Inside `psql`:

```sql
\conninfo
\l
\c backstage_plugin_catalog
\dn
\dt public.*
\q
```

Only connect to `backstage_plugin_catalog` if it appears in the database list.
Backstage creates plugin databases and tables when its backend initializes
successfully. A running frontend alone does not prove that this happened.
`getaddrinfo ENOTFOUND` means the configured database hostname cannot resolve;
fix that connection before expecting databases to appear.

For local PostgreSQL administration inside WSL, use:

```sh
sudo -u postgres psql
```

## 2. Find the server and client IP addresses

In WSL:

```sh
hostname -I
ip route show default
```

Use the WSL interface IP from `hostname -I` as the **server address in pgAdmin**.
Under default NAT networking, the address after `via` in the default route is
normally the Windows host address. The IP in a PostgreSQL rejection message is
the authoritative client address for that connection.

The addresses from this setup were:

| Role                  | Example address  | Where it goes                     |
| --------------------- | ---------------- | --------------------------------- |
| WSL PostgreSQL server | `172.28.118.152` | pgAdmin's Host name/address field |
| Windows client        | `172.28.112.1`   | The address rule in `pg_hba.conf` |

These are examples, not permanent values. WSL networking addresses can change
after a restart. Recheck them when reconnecting. Mirrored networking can use
different addresses; do not assume the NAT gateway instructions apply there.

## 3. Allow PostgreSQL to listen outside localhost

Inspect the active cluster configuration:

```sh
sudo -u postgres psql
```

```sql
SHOW port;
SHOW listen_addresses;
SHOW config_file;
SHOW hba_file;
\q
```

For this installation, the port is `5432` and the configuration files are:

```text
/etc/postgresql/14/main/postgresql.conf
/etc/postgresql/14/main/pg_hba.conf
```

Edit the file reported by `SHOW config_file`:

```sh
sudo nano /etc/postgresql/14/main/postgresql.conf
```

Change the existing setting to the following. Remove any leading `#` so the
setting is active:

```conf
listen_addresses = '*'
```

This listens on all interfaces. Keep client access restricted through the
specific address rule in the next step.

## 4. Allow the Windows client to authenticate

Edit the file reported by `SHOW hba_file`:

```sh
sudo nano /etc/postgresql/14/main/pg_hba.conf
```

Keep the existing local administration rules. Add this rule, replacing the
example IP with the current **Windows client IP** and `postgres` with your
database role if different:

```conf
host    all    postgres    172.28.112.1/32    scram-sha-256
```

`/32` allows that one IPv4 address. `all` permits the role to connect to the
different plugin databases, subject to its database privileges. Authentication
uses the PostgreSQL role's password, not your Windows or WSL login password.

The error in this setup reported client `172.28.112.1`. Rules for
`172.28.118.152` (the server) and `172.28.118.1` did not match it. Check every
octet: **112 is not 118**.

## 5. Apply and verify the changes

A change to `listen_addresses` requires a restart. This briefly disconnects
database clients:

```sh
sudo pg_ctlcluster 14 main restart
sudo -u postgres psql -c "SHOW listen_addresses;"
sudo ss -ltnp 'sport = :5432'
```

Expect `*` from SQL and listeners on `0.0.0.0:5432` and, where enabled,
`[::]:5432`. A listener only on `127.0.0.1:5432` cannot accept a connection
addressed to the WSL interface IP.

For subsequent changes to **only `pg_hba.conf`**, reload instead:

```sh
sudo pg_ctlcluster 14 main reload
```

## 6. Register the WSL server in Windows pgAdmin

Right-click **Servers → Register → Server** and enter:

| Field                | Value                                        |
| -------------------- | -------------------------------------------- |
| Name                 | `WSL PostgreSQL`                             |
| Host name/address    | Current WSL IP, for example `172.28.118.152` |
| Port                 | `5432`, or the value from `SHOW port`        |
| Maintenance database | `postgres` (check the spelling)              |
| Username             | Your `POSTGRES_USER`, such as `postgres`     |
| Password             | Your `POSTGRES_PASSWORD`                     |

Use the WSL IP rather than `localhost` for this connection so it does not
accidentally select the PostgreSQL server running on Windows.

Save, expand the new server, then right-click **Databases → Refresh**. Browse:

```text
WSL PostgreSQL
  Databases
    backstage_plugin_catalog
      Schemas
        public
          Tables
```

Right-click a table and choose **View/Edit Data → First 100 Rows** to inspect it.
Other plugin databases can include `backstage_plugin_auth`,
`backstage_plugin_scaffolder`, and `backstage_plugin_app`.

## Troubleshooting

| Symptom                             | Check                                                                                                                                    |
| ----------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Only Windows databases appear       | Register the WSL IP as a separate server; verify the selected pgAdmin connection.                                                        |
| `no pg_hba.conf entry for host ...` | Match the client IP and role from the error, check the active `hba_file`, then reload.                                                   |
| Password authentication fails       | Use the PostgreSQL role password. Successful local `sudo -u postgres psql` uses peer authentication and does not validate that password. |
| Database does not exist             | Use `postgres` as the maintenance database; verify spelling and list databases through WSL `psql`.                                       |
| Connection refused or timed out     | Check the current WSL IP, cluster status, listener, and firewall rules.                                                                  |
| Listener remains `127.0.0.1`        | Check for a commented setting or another config override, then restart the correct cluster.                                              |
| Connection breaks after WSL restart | Recheck both addresses; update pgAdmin's host and the client rule if necessary.                                                          |

Inspect parsed settings and access rules without printing passwords:

```sh
sudo -u postgres psql -c "SELECT sourcefile, sourceline, setting, applied, error FROM pg_file_settings WHERE name = 'listen_addresses';"
sudo -u postgres psql -c "SHOW hba_file;"
sudo -u postgres psql -c "SELECT line_number, type, database, user_name, address, auth_method, error FROM pg_hba_file_rules;"
```

`pg_hba_file_rules` describes the current file contents and parse errors; reload
successfully before assuming the running server uses your latest edits.
