git clone https://github.com/OpenSnaproute/flexSdk.git

virtualenv env
source env/bin/activate

python flexSdk/setup.py install

python

from flexswitchV2 import FlexSwitch
import json

redistribution = [{"Sources": "CONNECTED,STATIC", "Policy": "BGPPolicy"}]

core1 = FlexSwitch('172.17.0.2', 8080)
core2 = FlexSwitch('172.17.0.3', 8080)
access1 = FlexSwitch('172.17.0.4', 8080)
access2 = FlexSwitch('172.17.0.5', 8080)

## Core 1 Configuration
core1.createLogicalIntf(Name="loopback0", Type="Loopback").text

core1.updatePort(IntfRef="eth20", Speed=1000, AdminState="UP").text
core1.updatePort(IntfRef="eth21", Speed=1000, AdminState="UP").text
core1.updatePort(IntfRef="eth22", Speed=1000, AdminState="UP").text
core1.updatePort(IntfRef="eth23", Speed=1000, AdminState="UP").text

core1.createIPv4Intf(IntfRef="loopback0", IpAddr="10.1.255.1/32", AdminState="UP").text
core1.createIPv4Intf(IntfRef="eth20", IpAddr="10.1.0.0/31", AdminState="UP").text
core1.createIPv4Intf(IntfRef="eth21", IpAddr="10.1.0.2/31", AdminState="UP").text
core1.createIPv4Intf(IntfRef="eth22", IpAddr="10.1.1.0/31", AdminState="UP").text
core1.createIPv4Intf(IntfRef="eth23", IpAddr="10.1.1.2/31", AdminState="UP").text

core1.createPolicyCondition(Name="PolicyCondition1", Protocol="BGP", ConditionType="MatchDstIpPrefix", IpPrefix="10.0.0.0/8", MaskLengthRange="8-32").text
core1.createPolicyCondition(Name="PolicyCondition2", Protocol="BGP", ConditionType="MatchDstIpPrefix", IpPrefix="10.0.0.0/8", MaskLengthRange="8-32").text
core1.createPolicyCondition(Name="PolicyCondition2", Protocol="BGP", ConditionType="MatchProtocol").text

core1.createPolicyStmt(Name="PolicyStatement1", MatchConditions="all", Action="permit", Conditions=["PolicyCondition1", "PolicyCondition2"]).text

core1.createPolicyDefinition(Name="BGPPolicy", MatchType="all", PolicyType="BGP", Priority=10, StatementList=[{"Priority": 1, "Statement": "PolicyStatement1"},{"Priority": 2, "Statement": "PolicyStatement2"}]).text

core1.updateBGPGlobal(vrf="global", ASNum="4200000000", RouterId="10.1.255.1", UseMultiplePaths=True, EBGPMaxPaths=8, Redistribution=redistribution).text

## Core 2 Configuration
core2.createLogicalIntf(Name="loopback0", Type="Loopback").text

core2.updatePort(IntfRef="eth25", Speed=1000, AdminState="UP").text
core2.updatePort(IntfRef="eth26", Speed=1000, AdminState="UP").text
core2.updatePort(IntfRef="eth27", Speed=1000, AdminState="UP").text
core2.updatePort(IntfRef="eth28", Speed=1000, AdminState="UP").text

core2.createIPv4Intf(IntfRef="loopback0", IpAddr="10.1.255.2/32", AdminState="UP").text
core2.createIPv4Intf(IntfRef="eth25", IpAddr="10.1.0.1/31", AdminState="UP").text
core2.createIPv4Intf(IntfRef="eth26", IpAddr="10.1.0.3/31", AdminState="UP").text
core2.createIPv4Intf(IntfRef="eth27", IpAddr="10.1.2.0/31", AdminState="UP").text
core2.createIPv4Intf(IntfRef="eth28", IpAddr="10.1.2.2/31", AdminState="UP").text

core2.createPolicyCondition(Name="PolicyCondition1", Protocol="BGP", ConditionType="MatchDstIpPrefix", IpPrefix="10.0.0.0/8", MaskLengthRange="8-32").text
core2.createPolicyCondition(Name="PolicyCondition2", Protocol="BGP", ConditionType="MatchProtocol").text

core2.createPolicyStmt(Name="PolicyStatement1", MatchConditions="all", Action="permit", Conditions=["PolicyCondition1", "PolicyCondition2"]).text

core2.createPolicyDefinition(Name="BGPPolicy", MatchType="all", PolicyType="BGP", Priority=10, StatementList=[{"Priority": 1, "Statement": "PolicyStatement1"},{"Priority": 2, "Statement": "PolicyStatement2"}]).text

core2.updateBGPGlobal(vrf="global", ASNum="4200000001", RouterId="10.1.255.2", UseMultiplePaths=True, EBGPMaxPaths=8, Redistribution=redistribution).text

## Access 1 Configuration
access1.createLogicalIntf(Name="loopback0", Type="Loopback").text

access1.updatePort(IntfRef="eth30", Speed=1000, AdminState="UP").text
access1.updatePort(IntfRef="eth31", Speed=1000, AdminState="UP").text
access1.updatePort(IntfRef="eth32", Speed=1000, AdminState="UP").text

access1.createIPv4Intf(IntfRef="loopback0", IpAddr="10.1.255.3/32", AdminState="UP").text
access1.createIPv4Intf(IntfRef="eth30", IpAddr="10.1.1.1/31", AdminState="UP").text
access1.createIPv4Intf(IntfRef="eth31", IpAddr="10.1.2.3/31", AdminState="UP").text
access1.createIPv4Intf(IntfRef="eth32", IpAddr="10.1.3.0/31", AdminState="UP").text

access1.createPolicyCondition(Name="PolicyCondition1", Protocol="BGP", ConditionType="MatchDstIpPrefix", IpPrefix="10.0.0.0/8", MaskLengthRange="8-32").text
access1.createPolicyCondition(Name="PolicyCondition2", Protocol="BGP", ConditionType="MatchProtocol").text

access1.createPolicyStmt(Name="PolicyStatement1", MatchConditions="all", Action="permit", Conditions=["PolicyCondition1", "PolicyCondition2"]).text

access1.createPolicyDefinition(Name="BGPPolicy", MatchType="all", PolicyType="BGP", Priority=10, StatementList=[{"Priority": 1, "Statement": "PolicyStatement1"},{"Priority": 2, "Statement": "PolicyStatement2"}]).text

access1.updateBGPGlobal(vrf="global", ASNum="4200000002", RouterId="10.1.255.3", UseMultiplePaths=True, EBGPMaxPaths=8, Redistribution=redistribution).text

## Access 2 Configuration
access2.createLogicalIntf(Name="loopback0", Type="Loopback").text

access2.updatePort(IntfRef="eth40", Speed=1000, AdminState="UP").text
access2.updatePort(IntfRef="eth41", Speed=1000, AdminState="UP").text
access2.updatePort(IntfRef="eth42", Speed=1000, AdminState="UP").text

access2.createIPv4Intf(IntfRef="loopback0", IpAddr="10.1.255.4/32", AdminState="UP").text
access2.createIPv4Intf(IntfRef="eth40", IpAddr="10.1.2.1/31", AdminState="UP").text
access2.createIPv4Intf(IntfRef="eth41", IpAddr="10.1.1.3/31", AdminState="UP").text
access2.createIPv4Intf(IntfRef="eth42", IpAddr="10.1.4.0/31", AdminState="UP").text

access2.createPolicyCondition(Name="PolicyCondition1", Protocol="BGP", ConditionType="MatchDstIpPrefix", IpPrefix="10.0.0.0/8", MaskLengthRange="8-32").text
access2.createPolicyCondition(Name="PolicyCondition2", Protocol="BGP", ConditionType="MatchProtocol").text

access2.createPolicyStmt(Name="PolicyStatement1", MatchConditions="all", Action="permit", Conditions=["PolicyCondition1", "PolicyCondition2"]).text

access2.createPolicyDefinition(Name="BGPPolicy", MatchType="all", PolicyType="BGP", Priority=10, StatementList=[{"Priority": 1, "Statement": "PolicyStatement1"},{"Priority": 2, "Statement": "PolicyStatement2"}]).text

access2.updateBGPGlobal(vrf="global", ASNum="4200000003", RouterId="10.1.255.4", UseMultiplePaths=True, EBGPMaxPaths=8, Redistribution=redistribution).text
