# hull/ -- fittings for the box under the ship

Scripts that touch the HULL (the host a ship is raised on), not the
ship.  Nothing here runs at `./basilisk up`.

- `wg-spoke.sh` -- an IPv6-only hull borrows an IPv4 door: a WireGuard
  spoke to a dual-stack ship in the fleet that acts as hub, so the
  IPv4-only corners of the world (quicklisp.org, github.com) stay
  reachable while everything IPv6 goes direct.  One run, as root, with
  the three values the hub's keeper hands over.  The hub side lives
  with the ship that plays hub (for Gornskew, sally-stack/wg/).
