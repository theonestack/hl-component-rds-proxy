# rds-proxy CfHighlander Component

![cftest](https://github.com/theonestack/hl-component-rds-proxy/actions/workflows/rspec.yaml/badge.svg)

Creates a RDS proxy for use with AWS Aurora MySQL and Postgres engines.

```bash
kurgan add rds-proxy
```

## Requirements

## Parameters

| Name | Use | Default | Global | Type | Allowed Values |
| ---- | --- | ------- | ------ | ---- | -------------- |
| EnvironmentName | Tagging | dev | true | string
| EnvironmentType | Tagging | development | true | string | ['development','production']
| DnsDomain | create route53 record for the proxy endpoint | | false | string
| TargetDBClusterIdentifier | Aurora cluster to attach to the proxy | | false | string
| TargetDBClusterPort | Aurora cluster port | 5432 for postgres, 3306 for mysql | false | string
| DBClusterSecurityGroup | Aurora cluster security group id, a ingress rule is created on this security to allow access from the proxy | | false | AWS::EC2::SecurityGroup::Id
| ProxyName | name of the rds proxy required by cloudformation. this value prefixed with the environment name | rdsproxy | false | string
| SecretCredentials | secrets manager arn of the secret. | | false | string 
| IdleClientTimeout | proxy idle connection timeout in seconds | 120 | false | number
| RequireTLS |require tls connections to the proxy | true | false | boolean | true, false
| MaxConnectionsPercent | The maximum size of the connection pool for each target in a target group | 100 | false | number | min: 1, max: 100
| MaxIdleConnectionsPercent | Controls how actively the proxy closes idle database connections in the connection pool | 50 | false | number
| ConnectionBorrowTimeout | The number of seconds for a proxy to wait for a connection to become available in the connection pool | 120 | false | number
| VPCId | AWS VPC ID to put the proxy in | | false | string
| SubnetIds | list of subnet ids to put the proxy in | | false | CommaDelimitedList
| NamespaceId | if using aws service discovery | | false | string

## Configuration

**Postgres**

```yaml
database_engine: POSTGRESQL
```

**MySQL**

```yaml
database_engine: MYSQL
```

**User Authentication**

RDS proxy takes a list of users that can access the database through the proxy. 

Each user requires a secret in AWS Secrets Manager which contains the username and password in a json format.
The Secrets Manager ARN is required to be passed through as a parameter to the component. [Setting up database credentials in Secrets Manager](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-proxy-setup.html#rds-proxy-secrets-arns)

```json
{"username":"admin","password":"choose_your_own_password"}
```

A user is enabled by default with IAM authentication enabled. This user can be [disabled](tests/multiple_users.test.yaml) or [added](tests/multiple_users.test.yaml) onto.

```yaml
users:
  default:
    secret_arn_parameter: SecretCredentials
    iam_auth: REQUIRED # REQUIRED | DISABLED
```

IAM auth can also be [disabled](tests/disable_iam_auth.test.yaml) on the default user 

**Security Group Rules**

configure network access to the proxy, set a ingress rule on the security group. For further rule options see docs [here](https://github.com/theonestack/hl-component-lib-ec2#security-group-rules)

```yaml
security_group_rules:
  ingress:
    -
      from: 5432
      protocol: tcp
      security_group_id: ${MyAppSecurityGroupId}
      desc: access to the postgres port from another security group
```

**Other Config Options**

See the test configs in the [tests directory](tests/)

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