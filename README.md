#This Source code helps to deploy K3s cluster with one master and one node setup And once k3s cluster is deployed it deploys webapplication along with ha-proxy ingress.

Prerequisite: 
Before you start following below steps create a sshkey pair for your local server where you're going to run this whole terraform code. Run "ssh-keygen -f sshkey" and keep entering.

Steps to be followed:
1. Clone repo "git clone https://sample_terraformapp.git"
2. Create a variable fine terraform.ftvars including AWS_ACCESS_KEY and AWS_SECRET_KEY of IAM user that you will be creating in AWS console. 
3. Then run `terraform init`
It will initialize the terraform based on the terraform source code.
4. Run `terraform apply`
It will prompt for Entering "Yes", please enter the same.
5. ssh into "server" and get the contents of `/var/lib/rancher/k3s/server/node-token`
Once the step 4 is done you will see in your AWS console the K3s cluster with master and worker is created. Login to the k3s_server.
6. ssh into "node" and edit script at `/root/k3s.sh`, replacing the endpoint URL with the internal VPC DNS/IP of the "server" and the node token taken from server as in step 3. And run script `#sudo sh /root/k3s.sh`

7. `kubectl get nodes` should show two nodes registered
###############################################################

Once this is done You will Can login to master/worker and run to validate the resource "kubectl get all --all-namespaces". 
Note: For the moment code is deploying application and haxproxy in master node the same can be shifted cut pasting the file provisioner and remote_exec provisioner from server section ot instance.tf to worker section which are copying application manifests and haxproxy.

The Application server Details can be verified with `curl -I -H 'Host: foo.bar' 'http://<clusterIP/DNS_IP>:30279'` 

For more details on HAPROXY Setup: https://www.haproxy.com/blog/dissecting-the-haproxy-kubernetes-ingress-controller/

Thanks, connect for Anyhelp: pg3391@gmail.com
