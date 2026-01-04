# Hydro Framework Roadmap

## 1. Database & ORM Layer
- [ ] **Database Abstraction**: Create a generic `DatabaseDriver` interface (similar to `SessionDriver`).
- [ ] **Query Builder**: Fluent API for constructing SQL queries safely (`db.table('users').where('id', 1).get()`).
- [ ] **ORM (Antigravity Models)**:
    - Active Record pattern (`User.find(1)`)
    - Relationships (`user.posts()`, `post.comments()`)
    - Integration with Reflection system for mapping fields.
- [ ] **Migrations**: CLI commands to create and run schema migrations.

## 2. Authentication & Authorization
- [ ] **Auth Middleware**:
    - Attachments for `@Auth` or `@Guest` guards on Routes.
- [ ] **JWT / Session Auth**: Built-in support for multiple auth drivers.
- [ ] **Gates & Policies**:
    - `@Can('update', Post)` annotation for easy authorization checks.

## 3. CLI Tooling (Hydro CLI)
- [ ] **Generators**:
    - `hydro make:route UserRoute`
    - `hydro make:validator UserValidator`
    - `hydro make:model User`
- [ ] **Dev Server**: Integrated hot-reload runner (standardizing `hydro_watch.bat`).

## 4. Enhanced HTTP Features
- [ ] **Middleware System**:
    - Global middleware (logging, CORS).
    - Route-specific middleware via `@AttachTo`.
- [ ] **File Storage System**:
    - Abstraction for Local, S3, etc. (`Storage.disk('s3').put(...)`).

## 5. Template Engine Improvements
- [ ] **Logic Support**: Add loops (`@foreach`) and conditionals (`@if`) to `HydroTemplateEngine`.
- [ ] **Partials**: Support including other views (`@include('header')`).

## 6. Real-time Features
- [ ] **WebSocket Channels**:
    - Private checks and easy broadcasting (`Channel('chat').broadcast(msg)`).
