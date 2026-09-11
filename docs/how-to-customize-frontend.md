# How to customize the frontend

[Back to README](../README.md)

## Change the homepage

1. Edit the Getting Started content in
   [homeModule.tsx](../packages/app/src/modules/home/homeModule.tsx).
2. Change widget positions, toolkit links, and clocks under `app.extensions` in
   [app-config.yaml](../app-config.yaml).
3. To make Home the landing page, remove the `page:catalog` override that sets
   `path: /`. Add `path: /` inside the **existing** `page:home.config`, alongside
   `defaultConfig`. Keep the widget layout; do not add a duplicate `page:home` entry.
4. To populate Most Visited and Recently Visited, enable the two commented
   extensions: `api:home/visits` and `app-root-element:home/visit-listener`.
5. Restart after config edits and check `/` and `/catalog`. Navigate between pages
   to check visit tracking if enabled.

## Change sidebar and branding

1. Open [Sidebar.tsx](../packages/app/src/modules/nav/Sidebar.tsx).
2. Reorder `nav.take(...)` calls to change named items. `nav.rest(...)` displays
   remaining discovered items. Search and notifications are rendered separately.
3. Edit [SidebarLogo.tsx](../packages/app/src/modules/nav/SidebarLogo.tsx),
   [LogoFull.tsx](../packages/app/src/modules/nav/LogoFull.tsx), or
   [LogoIcon.tsx](../packages/app/src/modules/nav/LogoIcon.tsx) for logos.
4. Replace browser icons in [packages/app/public/](../packages/app/public/), and
   change `app.title` in config for the application title.
5. Check expanded/collapsed navigation and refresh the browser to verify assets.

## Add a widget or page

1. Follow [Add a plugin](how-to-add-plugin.md) for package installation and
   discovery. For a local home widget, use `HomePageWidgetBlueprint` as in
   `homeModule.tsx` and add the widget to that module's extensions.
2. For a new local module, export it and add it to `features` in
   [App.tsx](../packages/app/src/App.tsx).
3. Add the widget to the home configuration or configure the page extension as
   required by its blueprint.
4. Run `yarn tsc` and check the result in the browser. An existing user-customized
   home layout may need resetting before a new default layout is visible.

See the [frontend system](https://backstage.io/docs/frontend-system/) for extension
blueprints. Older `FlatRoutes` examples target a different app architecture.
