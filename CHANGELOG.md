## [Unreleased]

## [0.7.3](https://github.com/contriboss/no_fly_list/compare/no_fly_list/v0.7.2...no_fly_list/v0.7.3) (2025-10-06)


### Bug Fixes

* resolve SQLite ambiguous column name error with polymorphic tags ([#20](https://github.com/contriboss/no_fly_list/issues/20)) ([ac5d513](https://github.com/contriboss/no_fly_list/commit/ac5d5138f389d88e5475057c9ea2dd24a153074a))
* resolve test infrastructure issues across all Rails versions ([#22](https://github.com/contriboss/no_fly_list/issues/22)) ([1743358](https://github.com/contriboss/no_fly_list/commit/1743358debfa13b3d2b6afd37bf147e71a4c86bf))

## [0.7.2](https://github.com/contriboss/no_fly_list/compare/no_fly_list/v0.7.1...no_fly_list/v0.7.2) (2025-06-13)


### Bug Fixes

* correct generators and test them ([273f50f](https://github.com/contriboss/no_fly_list/commit/273f50f4607aa5645429d3f3a3359dd7ffc66e22))
* correct generators and test them ([b459060](https://github.com/contriboss/no_fly_list/commit/b45906025833c61a630ab9d266457361d14722f4))

## [0.7.1](https://github.com/contriboss/no_fly_list/compare/no_fly_list/v0.7.0...no_fly_list/v0.7.1) (2025-05-22)


### Bug Fixes

* Stringify transformer to avoid unbootable app in case Taggable a… ([57d9ee1](https://github.com/contriboss/no_fly_list/commit/57d9ee10ef84c7f01f78646b95ec2d340b135cde))
* Stringify transformer to avoid unbootable app in case Taggable app was used before generating the Application transformer ([07ca0e9](https://github.com/contriboss/no_fly_list/commit/07ca0e98a4e94b95e1505c2d312a01e53bb2118e))

## [0.7.0](https://github.com/contriboss/no_fly_list/compare/no_fly_list/v0.6.0...no_fly_list/v0.7.0) (2025-03-22)


### Features

* fix TaggingProxy to handle clear operations and improve tag management ([027a603](https://github.com/contriboss/no_fly_list/commit/027a603b390ba9094913ea6d0bb6a531eb049202))
* refactor TaggingProxy to use nil for pending changes and improve tag handling ([9defb2d](https://github.com/contriboss/no_fly_list/commit/9defb2d8bf5d938a8902c18c3826285a561ea048))
* Update TaggingProxy tests to use Car model ([4395c3a](https://github.com/contriboss/no_fly_list/commit/4395c3a154df2586692b74d76ce1ab342798ef03))

## [0.6.0](https://github.com/contriboss/no_fly_list/compare/no_fly_list/v0.5.0...no_fly_list/v0.6.0) (2024-12-20)


### Features

* **tasks:** add db schema validation tasks for tags/taggings ([03742bd](https://github.com/contriboss/no_fly_list/commit/03742bda81e910dc21f9cff5496743d15504565e))

## [0.5.0](https://github.com/contriboss/no_fly_list/compare/no_fly_list/v0.4.0...no_fly_list/v0.5.0) (2024-12-19)


### Features

* **tagging:** support comma-separated tags in add/remove methods ([453286d](https://github.com/contriboss/no_fly_list/commit/453286d6849919f24c86fbed15dad52122b7202c))

## [0.4.0](https://github.com/contriboss/no_fly_list/compare/no_fly_list/v0.3.0...no_fly_list/v0.4.0) (2024-12-19)


### Features

* **counter-cache:** Add counter support for tag contexts ([#7](https://github.com/contriboss/no_fly_list/issues/7)) ([8e11848](https://github.com/contriboss/no_fly_list/commit/8e11848abae940d82e4eb26982f197e0ac097cf9))

## [0.3.0](https://github.com/contriboss/no_fly_list/compare/no_fly_list/v0.2.1...no_fly_list/v0.3.0) (2024-12-19)


### Features

* Add change tracking to tag lists ([7ecc8ba](https://github.com/contriboss/no_fly_list/commit/7ecc8ba1af3e989a9da4eb8e0b6ea7769fedb056))

## [0.2.1](https://github.com/contriboss/no_fly_list/compare/no_fly_list/v0.2.0...no_fly_list/v0.2.1) (2024-12-19)


### Bug Fixes

* no_fly_list:transformer fix ([f1f9f0f](https://github.com/contriboss/no_fly_list/commit/f1f9f0f46eac2bc9376ab043aff57b4c57dd74f2))

## 0.2.0 (2024-12-09)


### Features

* add releaseplease workflow ([f2222b4](https://github.com/contriboss/no_fly_list/commit/f2222b4a00976fdd721fad328e1ec9951caf7a2e))
* remove OpenStruct dependency ([b6b15b8](https://github.com/contriboss/no_fly_list/commit/b6b15b853a0af1fa2544f936d4dcb49646ecd469))
* test with all adapters ([#3](https://github.com/contriboss/no_fly_list/issues/3)) ([792a62e](https://github.com/contriboss/no_fly_list/commit/792a62e9ae8276a246109cb90fec894b49e6141a))

## [0.0.1] - 2024-12-02

- Initial release
