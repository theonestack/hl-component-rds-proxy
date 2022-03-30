CloudFormation do
    
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
    RoleArn Ref(:SecretsManagerRole)
    VpcSecurityGroupIds Ref(:SecurityGroup)
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
    DBClusterIdentifiers Ref(:TargetDBClusterIdentifier)
    TargetGroupName 'default' # Currently, this property must be set to default. https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-rds-dbproxytargetgroup.html
  }

  Output(:ProxyWriterEndpoint) {
    Value FnGetAtt(:RdsProxy, :Endpoint)
    Export FnSub("${EnvironmentName}-#{external_parameters[:component_name]}-writer-endpoint")
  }

  Output(:ProxyArn) {
    Value FnGetAtt(:RdsProxy, :DBProxyArn)
    Export FnSub("${EnvironmentName}-#{external_parameters[:component_name]}-arn")
  }

end
