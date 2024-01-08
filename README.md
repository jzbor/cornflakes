# Nix Cornflakes

My personal flake library.

*At the moment this library is **unstable and not intended for general use**.
Feel free though to copy anything you find useful.*

## Gitlab CI
This Flake provides an easy way to add a CI to your projects on Gitlab.
The CI will automatically determine members of `outputs.packages` and create build jobs for each one of them.

To add the CI to your project copy the [`gitlab-ci.yml` file](./gitlab-ci/gitlab-ci.yml) to `.gitlab-ci.yml` or run the following command in your project root:
```sh
nix run github:jzbor/cornflakes#add-gitlab-ci
```

You can enable/disable specific builds by adding them to `.ci-enabled`/`ci-disabled` respectively.
Each line represents one output package.
If `.ci-enabled` exists only packages specified in that file will be built.
If `.ci-disabled` exists no packages specified in that file will be built.
