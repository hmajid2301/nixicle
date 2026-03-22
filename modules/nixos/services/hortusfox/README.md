# HortusFox NixOS Module

A self-hosted collaborative plant management system with Authentik SSO integration via proxy authentication.

## Features

- **HortusFox Web**: Plant management and tracking system
- **MariaDB Database**: Persistent storage for plant data
- **Authentik SSO**: Single sign-on via proxy authentication (forward auth)
- **Cloudflare Tunnel**: Secure external access without opening ports
- **Traefik**: Reverse proxy with automatic HTTPS

## Authentication

HortusFox does **not** have native OIDC/OAuth support. Instead, this module uses **Proxy Authentication** which is compatible with Authentik's Forward Auth middleware.

When a user accesses HortusFox:
1. Traefik routes the request through Authentik's forward auth middleware
2. Authentik authenticates the user and sets headers (`X-authentik-username`, `X-authentik-email`)
3. HortusFox reads these headers and automatically creates/logs in the user
4. Password authentication is hidden when using proxy auth

## Setup

### 1. Enable the service

Add to your host configuration:

```nix
services.nixicle.hortusfox = {
  enable = true;
  domain = "plants.haseebmajid.dev";  # Change to your domain
  admin.email = "admin@haseebmajid.dev";  # Change to your email
};
```

### 2. Add Secrets

The module requires database and admin passwords. Add these to `modules/nixos/services/secrets.yaml`:

```bash
# Edit the secrets file
sops modules/nixos/services/secrets.yaml
```

Add the following content:

```yaml
hortusfox_env: |
  APP_ADMIN_PASSWORD=your-secure-admin-password
  DB_PASSWORD=your-secure-db-password
  MARIADB_ROOT_PASSWORD=your-secure-root-password
  MARIADB_PASSWORD=your-secure-db-password
```

**Important**: Use the same password for `DB_PASSWORD` and `MARIADB_PASSWORD` since they refer to the same database user.

### 3. Configure Authentik Provider

In your Authentik instance:

1. Go to **Applications** → **Providers** → **Create**
2. Select **Proxy Provider**
3. Configure:
   - Name: `hortusfox`
   - Internal host: `http://hortusfox:8080` (or your internal URL)
   - External host: `https://plants.haseebmajid.dev` (your domain)
   - Skip path regex: Leave empty or add paths that don't need auth
4. Save and bind to an application

### 4. Deploy

```bash
sudo nixos-rebuild switch --flake .#your-hostname
```

## Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `enable` | `false` | Enable the service |
| `domain` | `plants.haseebmajid.dev` | External domain |
| `port` | `8080` | Internal port |
| `dataDir` | `/var/lib/hortusfox` | Data storage directory |
| `admin.email` | `admin@haseebmajid.dev` | Admin user email |
| `authentik.enable` | `true` | Enable Authentik forward auth |

## Data Storage

The following directories are created in `dataDir`:

- `images/` - Plant photos
- `logs/` - Application logs
- `backup/` - Backup files
- `themes/` - Custom themes
- `migrations/` - Database migrations
- `db/` - MariaDB data

## Troubleshooting

### Check container status

```bash
sudo podman ps -a | grep hortusfox
sudo podman logs hortusfox
sudo podman logs hortusfox-db
```

### View service status

```bash
sudo systemctl status podman-hortusfox
sudo systemctl status podman-hortusfox-db
```

### Database connection issues

If the app can't connect to the database:
1. Check that both containers are on the same network: `sudo podman network ls`
2. Verify the database container is healthy: `sudo podman ps -a`
3. Check logs: `sudo podman logs hortusfox-db`

### Authentik auth not working

1. Verify the middleware is applied in Traefik dashboard
2. Check Authentik outpost logs
3. Ensure the external host matches your domain exactly

## Using compose2nix Alternative

If you prefer using the Docker Compose approach with [compose2nix](https://github.com/aksiksi/compose2nix):

1. Create a `docker-compose.yml` for hortusfox (from the upstream repo)
2. Run: `compose2nix -inputs docker-compose.yml -output hortusfox.nix`
3. Import the generated module

However, this Nix module provides better integration with:
- Secrets management via sops-nix
- Traefik/Authentik automatic configuration
- Cloudflare tunnel integration
- Impermanence support

## References

- [HortusFox GitHub](https://github.com/danielbrendel/hortusfox-web)
- [HortusFox Documentation](https://hortusfox.github.io/)
- [Authentik Forward Auth](https://docs.goauthentik.io/docs/providers/proxy/)
- [compose2nix](https://github.com/aksiksi/compose2nix)
