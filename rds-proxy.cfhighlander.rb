CfhighlanderTemplate do
  Name 'rds-proxy'
  Description "rds-proxy - #{component_version}"

  DependsOn 'lib-iam@0.2.0'
  DependsOn 'lib-ec2@0.2.1'

  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', allowedValues: ['development','production'], isGlobal: true
    ComponentParam 'DnsDomain', ''

    ComponentParam 'TargetDBClusterIdentifier', description: 'RDS Aurora cluster identifer to connect to the proxy'
    ComponentParam 'TargetDBClusterPort', database_engine == 'POSTGRESQL' ? '5432': '3306', description: 'RDS Aurora cluster identifer to connect to the proxy'
    ComponentParam 'DBClusterSecurityGroup', type: 'AWS::EC2::SecurityGroup::Id'
    
    ComponentParam 'ProxyName', 'rdsproxy', description: 'name of the rds proxy required by cloudformation. this value prefixed with the environment name'
    ComponentParam 'SecretCredentials', description: 'secrets manager arn of the secret. format of the secret must be json {"username": "user", "password": "pass"}'

    ComponentParam 'IdleClientTimeout', 120, type: 'Number', 
      description: 'proxy idle connection timeout in seconds'
    ComponentParam 'RequireTLS', 'true', allowedValues: ['true', 'false'], 
      description: 'require tls connections to the proxy'

    ComponentParam 'MaxConnectionsPercent', 100, type: 'Number', minValue: 1, maxValue: 100, 
      description: 'The maximum size of the connection pool for each target in a target group'
    ComponentParam 'MaxIdleConnectionsPercent', 50, type: 'Number', 
      description: 'Controls how actively the proxy closes idle database connections in the connection pool'
    ComponentParam 'ConnectionBorrowTimeout', 120, type: 'Number', 
      description: 'The number of seconds for a proxy to wait for a connection to become available in the connection pool'

    ComponentParam 'VPCId'
    ComponentParam 'SubnetIds', type: 'CommaDelimitedList'

    ComponentParam 'NamespaceId' if defined? service_discovery
  end


end
