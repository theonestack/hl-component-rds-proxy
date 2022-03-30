require 'yaml'

describe 'compiled component rds-proxy' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/default.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/default/rds-proxy.compiled.yaml") }
  
  context "Resource" do

    
    context "SecurityGroup" do
      let(:resource) { template["Resources"]["SecurityGroup"] }

      it "is of type AWS::EC2::SecurityGroup" do
          expect(resource["Type"]).to eq("AWS::EC2::SecurityGroup")
      end
      
      it "to have property VpcId" do
          expect(resource["Properties"]["VpcId"]).to eq({"Ref"=>"VPCId"})
      end
      
      it "to have property GroupDescription" do
          expect(resource["Properties"]["GroupDescription"]).to eq({"Fn::Join"=>[" ", [{"Ref"=>"EnvironmentName"}, "rds-proxy", "security group"]]})
      end
      
      it "to have property Tags" do
          expect(resource["Properties"]["Tags"]).to eq([{"Key"=>"Name", "Value"=>{"Fn::Sub"=>"${EnvironmentName}-rds-proxy"}}, {"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}}])
      end
      
    end
    
    context "RdsProxy" do
      let(:resource) { template["Resources"]["RdsProxy"] }

      it "is of type AWS::RDS::DBProxy" do
          expect(resource["Type"]).to eq("AWS::RDS::DBProxy")
      end
      
      it "to have property Auth" do
          expect(resource["Properties"]["Auth"]).to eq([{"AuthScheme"=>"SECRETS", "IAMAuth"=>"REQUIRED", "SecretArn"=>{"Ref"=>"SecretCredentials"}}])
      end
      
      it "to have property EngineFamily" do
          expect(resource["Properties"]["EngineFamily"]).to eq("MYSQL")
      end
      
      it "to have property IdleClientTimeout" do
          expect(resource["Properties"]["IdleClientTimeout"]).to eq({"Ref"=>"IdleClientTimeout"})
      end
      
      it "to have property RequireTLS" do
          expect(resource["Properties"]["RequireTLS"]).to eq({"Ref"=>"RequireTLS"})
      end
      
      it "to have property DBProxyName" do
          expect(resource["Properties"]["DBProxyName"]).to eq({"Fn::Sub"=>"${EnvironmentName}-${ProxyName}"})
      end
      
      it "to have property RoleArn" do
          expect(resource["Properties"]["RoleArn"]).to eq({"Ref"=>"SecretsManagerRole"})
      end
      
      it "to have property VpcSecurityGroupIds" do
          expect(resource["Properties"]["VpcSecurityGroupIds"]).to eq({"Ref"=>"SecurityGroup"})
      end
      
      it "to have property VpcSubnetIds" do
          expect(resource["Properties"]["VpcSubnetIds"]).to eq({"Ref"=>"SubnetIds"})
      end
      
      it "to have property Tags" do
          expect(resource["Properties"]["Tags"]).to eq([{"Key"=>"Name", "Value"=>{"Fn::Sub"=>"${EnvironmentName}-rds-proxy"}}, {"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}}])
      end
      
    end
    
    context "SecretsManagerRole" do
      let(:resource) { template["Resources"]["SecretsManagerRole"] }

      it "is of type AWS::IAM::Role" do
          expect(resource["Type"]).to eq("AWS::IAM::Role")
      end
      
      it "to have property AssumeRolePolicyDocument" do
          expect(resource["Properties"]["AssumeRolePolicyDocument"]).to eq({"Version"=>"2012-10-17", "Statement"=>[{"Effect"=>"Allow", "Principal"=>{"Service"=>"rds.amazonaws.com"}, "Action"=>"sts:AssumeRole"}]})
      end
      
      it "to have property Policies" do
          expect(resource["Properties"]["Policies"]).to eq([{"PolicyName"=>"getsecret", "PolicyDocument"=>{"Statement"=>[{"Sid"=>"getsecret", "Action"=>["secretsmanager:GetSecretValue"], "Resource"=>[{"Ref"=>"SecretCredentials"}], "Effect"=>"Allow"}]}}])
      end
      
    end
    
    context "ProxyTargetGroup" do
      let(:resource) { template["Resources"]["ProxyTargetGroup"] }

      it "is of type AWS::RDS::DBProxyTargetGroup" do
          expect(resource["Type"]).to eq("AWS::RDS::DBProxyTargetGroup")
      end
      
      it "to have property ConnectionPoolConfigurationInfo" do
          expect(resource["Properties"]["ConnectionPoolConfigurationInfo"]).to eq({"MaxConnectionsPercent"=>{"Ref"=>"MaxConnectionsPercent"}, "MaxIdleConnectionsPercent"=>{"Ref"=>"MaxIdleConnectionsPercent"}, "ConnectionBorrowTimeout"=>{"Ref"=>"ConnectionBorrowTimeout"}})
      end
      
      it "to have property DBProxyName" do
          expect(resource["Properties"]["DBProxyName"]).to eq({"Ref"=>"RdsProxy"})
      end
      
      it "to have property DBClusterIdentifiers" do
          expect(resource["Properties"]["DBClusterIdentifiers"]).to eq({"Ref"=>"TargetDBClusterIdentifier"})
      end
      
      it "to have property TargetGroupName" do
          expect(resource["Properties"]["TargetGroupName"]).to eq("default")
      end
      
    end
    
  end

end