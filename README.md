# rds-proxy CfHighlander Component

![cftest](https://github.com/theonestack/hl-component-rds-proxy/actions/workflows/rspec.yaml/badge.svg)

<!--- add component description --->

```bash
kurgan add rds-proxy
```

## Requirements

## Parameters

| Name | Use | Default | Global | Type | Allowed Values |
| ---- | --- | ------- | ------ | ---- | -------------- |


## Configuration

<!--- add component config examples --->

```yaml
example_config: test
```

## Outputs/Exports

| Name | Value | Exported |
| ---- | ----- | -------- |


## Development

```bash
gem install cfhighlander
```

or via docker

```bash
docker pull theonestack/cfhighlander
```

### Testing

Generate cftest

```bash
kurgan test example
```

Run cftest

```bash
cfhighlander cftest -t tests/example.test.yaml
```

or run all tests

```bash
cfhighlander cftest
```

Generate spec tests

```bash
kurgan test example --type spec
```

run spec tests

```bash
gem install rspec
```

```bash
rspec
```