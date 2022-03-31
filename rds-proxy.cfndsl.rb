CloudFormation do

  Condition(:CreateHostRecord, FnNot(FnEquals(Ref(:DnsDomain), '')))

  proxy_tags = []
  proxy_tags << { Key: 'Name', Value: FnSub("${EnvironmentName}-#{component_name}") }
  proxy_tags << { Key: 'Environment', Value: Ref(:EnvironmentName) }
  proxy_tags << { Key: 'EnvironmentType', Value: Ref(:EnvironmentType) }
  proxy_tags.push(*tags.map {|k,v| {Key: k, Value: FnSub(v)}}).uniq { |h| h[:Key] } if defined? tags


  security_group_rules = external_parameters.fetch(:security_group_rules, {})
  ip_blocks = external_parameters.fetch(:ip_blocks, [])

  EC2_SecurityGroup(:SecurityGroup) {
    VpcId Ref('VPCId')
    GroupDescription FnJoin(' ', [ Ref(:EnvironmentName), external_parameters[:component_name], 'security group' ])
    
    if security_group_rules.has_key?('ingress')
      SecurityGroupEgress generate_security_group_rules(security_group_rules['ingress'], ip_blocks, true)
    end
    
    if security_group_rules.has_key?('egress')
      SecurityGroupEgress generate_security_group_rules(security_group_rules['egress'], ip_blocks, false)
    end
    
    Tags proxy_tags
  }

  RDS_DBProxy(:RdsProxy) {
    Auth([
      {
        AuthScheme: 'SECRETS',
        IAMAuth: external_parameters[:iam_auth],
        SecretArn: Ref(:SecretCredentials)
      }
    ])
    EngineFamily database_engine
    IdleClientTimeout Ref(:IdleClientTimeout)
    RequireTLS Ref(:RequireTLS)
    DBProxyName FnSub("${EnvironmentName}-${ProxyName}")
    RoleArn FnGetAtt(:SecretsManagerRole, :Arn)
    VpcSecurityGroupIds [Ref(:SecurityGroup)]
    VpcSubnetIds Ref(:SubnetIds)
    Tags proxy_tags
  }

  IAM_Role(:SecretsManagerRole) {
    AssumeRolePolicyDocument service_assume_role_policy('rds')
    Policies iam_role_policies({
      'getsecret' => {
        'action' => ['secretsmanager:GetSecretValue'],
        'resource' => Ref(:SecretCredentials)
      }
    })
  }

  RDS_DBProxyTargetGroup(:ProxyTargetGroup) {
    ConnectionPoolConfigurationInfo({
      MaxConnectionsPercent: Ref(:MaxConnectionsPercent),
      MaxIdleConnectionsPercent: Ref(:MaxIdleConnectionsPercent),
      ConnectionBorrowTimeout: Ref(:ConnectionBorrowTimeout)
    })
    DBProxyName Ref(:RdsProxy)
    DBClusterIdentifiers [Ref(:TargetDBClusterIdentifier)]
    TargetGroupName 'default' # Currently, this property must be set to default. https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-rds-dbproxytargetgroup.html
  }

  Route53_RecordSet(:ProxyRecord) {
    Condition(:CreateHostRecord)
    HostedZoneName FnSub("#{external_parameters[:dns_format]}.")
    Name FnSub("#{external_parameters[:hostname]}.#{external_parameters[:dns_format]}.")
    Type 'CNAME'
    TTL '60'
    ResourceRecords [ FnGetAtt(:RdsProxy, :Endpoint) ]
  }

  registry = {}
  service_discovery = external_parameters.fetch(:service_discovery, {})

  unless service_discovery.empty?
    ServiceDiscovery_Service(:ServiceRegistry) {
      NamespaceId Ref(:NamespaceId)
      Name service_discovery['name']  if service_discovery.has_key? 'name'
      DnsConfig({
        DnsRecords: [{
          TTL: 60,
          Type: 'CNAME'
        }],
        RoutingPolicy: 'WEIGHTED'
      })
      if service_discovery.has_key? 'healthcheck'
        HealthCheckConfig service_discovery['healthcheck']
      else
        HealthCheckCustomConfig ({ FailureThreshold: (service_discovery['failure_threshold'] || 1) })
      end
    }

    ServiceDiscovery_Instance(:RegisterInstance) {
      InstanceAttributes(
        AWS_INSTANCE_CNAME: FnGetAtt(:RdsProxy, :Endpoint)
      )
      ServiceId Ref(:ServiceRegistry)
    }

    Output(:ServiceRegistry) {
      Value(Ref(:ServiceRegistry))
      Export FnSub("${EnvironmentName}-#{external_parameters[:component_name]}-CloudMapService")
    }
  end

  Output(:ProxyName) {
    Value Ref(:RdsProxy)
    Export FnSub("${EnvironmentName}-#{external_parameters[:component_name]}-name")
  }

  Output(:ProxyEndpoint) {
    Value FnGetAtt(:RdsProxy, :Endpoint)
    Export FnSub("${EnvironmentName}-#{external_parameters[:component_name]}-endpoint")
  }

  Output(:ProxyArn) {
    Value FnGetAtt(:RdsProxy, :DBProxyArn)
    Export FnSub("${EnvironmentName}-#{external_parameters[:component_name]}-arn")
  }

end
