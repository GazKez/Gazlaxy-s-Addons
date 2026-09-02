# Home Assistant packaging notes

This directory vendors `amuleweb-adaptable` at commit
`c13554128c1dde53625781f22a497a10e042d7da`. The upstream project is licensed
under GPL-3.0; its original `README.md` and `LICENSE` are preserved here.

The Home Assistant package makes these compatibility changes:

- external Bootstrap and animate.css resources are stored locally so Ingress
  does not depend on third-party CDNs;
- absolute stylesheet paths are relative so they work below the Ingress path;
- the Kad and statistics pages include a mobile viewport declaration.

Bootstrap, jQuery and animate.css are distributed under the MIT license. Their
license texts are stored in `vendor/licenses`.
