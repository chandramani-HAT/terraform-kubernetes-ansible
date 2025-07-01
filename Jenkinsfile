pipeline {
  agent any

  environment {
    PEM_FILE = credentials('terraform_ansible.pem')  
  }

  stages {
    stage('Checkout') {
    steps {
        git(
        branch: 'main',
        credentialsId: 'github-repo',
        url: 'https://github.com/chandramani-HAT/terraform-kubernetes-ansible.git'
        )
    }
    }

    stage('Terraform Init & Validate') {
      steps {
        dir('terraform') {
          sh 'terraform init --migrate-state'
          sh 'terraform validate'
          sh 'terraform plan -out=tfplan'
        }
      }
    }

    stage('Terraform Apply') {
      steps {
        dir('terraform') {
          sh 'terraform destroy -auto-approve tfplan'
        }
      }
    }

    stage('Fetch EC2 Public IPs') {
      steps {
        script {
          // Run in terraform directory with correct output name
          dir('terraform') {
            def ipsJson = sh(script: "terraform output -json ec2_instance_public_ips", returnStdout: true).trim()
            env.EC2_IPS_JSON = ipsJson
          }
          echo "EC2 Public IPs JSON: ${env.EC2_IPS_JSON}"
        }
      }
    }

 stage('Generate Ansible Inventory') {
  steps {
    dir('ansible') {
      script {
        def ips = readJSON text: env.EC2_IPS_JSON
        def inventoryContent = """all:
  hosts:
"""
        ips.eachWithIndex { ip, idx ->
          def hostname = "ec2-${idx+1}"
          inventoryContent += """    ${hostname}:
      ansible_host: ${ip}
      ansible_user: ubuntu
      ansible_ssh_private_key_file: ${env.PEM_FILE}
"""
        }
        inventoryContent += """  children:
    ec2_instances:
      hosts:
"""
        ips.eachWithIndex { ip, idx ->
          def hostname = "ec2-${idx+1}"
          inventoryContent += "        ${hostname}: {}\n"
        }

        writeFile file: 'inventory.yaml', text: inventoryContent
        echo "Generated ansible/inventory.yaml:\n${inventoryContent}"
      }
    }
  }
}

stage('Establish Passwordless SSH') {
  steps {
    dir('ansible') {
      script {
        // Generate public key from PEM if not present
        sh '''
          mkdir -p ~/.ssh
          if [ ! -f "$PEM_FILE.pub" ]; then
            ssh-keygen -y -f $PEM_FILE > $PEM_FILE.pub
          fi
        '''
        def ips = readJSON text: env.EC2_IPS_JSON
        ips.each { ip ->
  // Wait for SSH to be available
  sh """
    for i in {1..30}; do
      if ssh -o StrictHostKeyChecking=no -i $PEM_FILE -o ConnectTimeout=5 ubuntu@$ip 'echo SSH is up' 2>/dev/null; then
        echo "SSH is ready on $ip"
        break
      fi
      echo "Waiting for SSH on $ip..."
      sleep 5
    done
  """
  // Now copy the key
  sh '''
    ssh-keygen -R $ip || true
    ssh-copy-id -i $PEM_FILE.pub -o StrictHostKeyChecking=no ubuntu@$ip
  '''.replace('$ip', ip)
}

      }
    }
  }
}
 
    stage('Run Ansible Playbook') {
      steps {
        dir('ansible') {
          sh 'ansible-playbook -i inventory.yaml playbook.yaml'
        }
      }
    }
  }
}
