# Library & Resource Management System — Ballerina Client (Person 4)

A command-line Ballerina client for the REST API implemented by Persons 1–3.
It demonstrates:

1. **Loan / Book a Resource** — loan out an asset (e.g. a laptop) or book a
   room/lab for a date, updating its status and schedule in one call.
2. **Global Asset View** — list every asset across every institution.
3. **Campus / Institution View** — filter assets by institution and/or site.
4. **Overdue Dashboard** — list assets with a maintenance/servicing date that
   has passed, optionally filtered by institution/site/as-of date.
5. **Schedule Manager** — add, update, or delete booking/maintenance/
   servicing schedules for a chosen asset.

## Project layout

This client is its own Ballerina package (separate from the API service
package that contains `api.bal`, `Q1.bal`, etc.), so it can be built and run
independently:

```
library_client/
├── Ballerina.toml     # package manifest
├── Config.toml        # apiBaseUrl configuration
├── types.bal          # record types mirroring the API's data model
├── client_ops.bal      # shared http:Client + request helpers
├── display.bal        # console table/summary formatting helpers
├── menu_loan.bal       # Task 1: Loaning & Booking
├── menu_views.bal      # Tasks 2 & 3 & 4: Global / Campus / Overdue views
├── menu_schedule.bal   # Task 5: Schedule Manager
└── main.bal            # menu loop / entry point
```

## Running it

1. Start the API service first (from the service package root), e.g.:

   ```
   bal run
   ```

   By its `Config.toml`, the service listens on port `9091`.

2. In a separate terminal, run the client from this folder:

   ```
   bal run
   ```

   It defaults to `http://localhost:9091/api`. If your service runs on a
   different host/port, change `apiBaseUrl` in this folder's `Config.toml`.

3. Use the on-screen menu to loan/book assets, browse the ministry-wide asset
   list, filter by campus, check overdue maintenance, and manage schedules.
