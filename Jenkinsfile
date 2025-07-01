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
          sh 'terraform init'
          sh 'terraform validate'
          sh 'terraform plan -out=tfplan'
        }
      }
    }

    stage('Terraform Apply') {
      steps {
        dir('terraform') {
          sh 'terraform apply -auto-approve tfplan'
        }
      }
    }

    stage('Fetch Node IPs') {
      steps {
        script {
          dir('terraform') {
            // Fetch master IPs
            def masterIps = sh(
              script: "terraform output -json master_ips", 
              returnStdout: true
            ).trim()
            env.MASTER_IPS_JSON = masterIps

            // Fetch worker IPs
            def workerIps = sh(
              script: "terraform output -json worker_ips", 
              returnStdout: true
            ).trim()
            env.WORKER_IPS_JSON = workerIps
          }
        }
      }
    }

    stage('Fetch Master Private IP') {
  steps {
    dir('terraform') {
      script {
        env.MASTER_PRIVATE_IP = sh(
          script: "terraform output -raw master_private_ip", 
          returnStdout: true
        ).trim()
      }
    }
  }
}
    stage('Generate Ansible Inventory') {
      steps {
        dir('ansible') {
          script {
            def masterIps = readJSON text: env.MASTER_IPS_JSON
            def workerIps = readJSON text: env.WORKER_IPS_JSON
            
            def inventoryContent = """all:
  hosts:
    master:
      ansible_host: ${masterIps[0]}
      ansible_user: ubuntu
      ansible_ssh_private_key_file: ${env.PEM_FILE}
"""

            workerIps.eachWithIndex { ip, idx ->
              def hostname = "worker${idx+1}"
              inventoryContent += """    ${hostname}:
      ansible_host: ${ip}
      ansible_user: ubuntu
      ansible_ssh_private_key_file: ${env.PEM_FILE}
"""
            }

            inventoryContent += """  children:
    master_group:
      hosts:
        master:
    worker_group:
      hosts:
"""
            workerIps.eachWithIndex { ip, idx ->
              def hostname = "worker${idx+1}"
              inventoryContent += "        ${hostname}:\n"
            }

            writeFile file: 'inventory.yaml', text: inventoryContent
            echo "Generated inventory:\n${inventoryContent}"
          }
        }
      }
    }

    stage('Establish Passwordless SSH') {
      steps {
        dir('ansible') {
          script {
            // Generate public key from PEM using safe variable handling
            sh """
              mkdir -p ~/.ssh
              ssh-keygen -y -f "${env.PEM_FILE}" > "${env.PEM_FILE}.pub"
            """
            
            def masterIps = readJSON text: env.MASTER_IPS_JSON
            def workerIps = readJSON text: env.WORKER_IPS_JSON
            def allIps = masterIps + workerIps

            allIps.each { ip ->
              // Wait for SSH access
              sh """
                for i in {1..30}; do
                  if ssh -o StrictHostKeyChecking=no -i "${env.PEM_FILE}" -o ConnectTimeout=5 ubuntu@${ip} 'echo SSH ready' 2>/dev/null; then
                    echo "SSH active on ${ip}"
                    break
                  fi
                  echo "Waiting for SSH on ${ip}..."
                  sleep 5
                done
              """
              
              // Copy SSH key
              sh """
                ssh-keygen -R ${ip} || true
                ssh-copy-id -i "${env.PEM_FILE}.pub" -o StrictHostKeyChecking=no ubuntu@${ip}
              """
            }
          }
        }
      }
    }

// stage('Generate Ansible Inventory') {
//   steps {
//     dir('ansible') {
//       script {
//         def masterIps = readJSON text: env.MASTER_IPS_JSON
//         def workerIps = readJSON text: env.WORKER_IPS_JSON
        
//         def inventoryContent = """all:
//   hosts:
//     master:
//       ansible_host: ${masterIps[0]}
//       ansible_user: ubuntu
//       ansible_ssh_private_key_file: ${env.PEM_FILE}
// """

//         workerIps.eachWithIndex { ip, idx ->
//           def hostname = "worker${idx+1}"
//           inventoryContent += """    ${hostname}:
//       ansible_host: ${ip}
//       ansible_user: ubuntu
//       ansible_ssh_private_key_file: ${env.PEM_FILE}
// """
//         }

//         inventoryContent += """  children:
//     master_group:
//       hosts:
//         master:
//     worker_group:
//       hosts:
// """
//         workerIps.eachWithIndex { ip, idx ->
//           def hostname = "worker${idx+1}"
//           inventoryContent += "        ${hostname}:\n"
//         }

//         writeFile file: 'inventory.yaml', text: inventoryContent
//         echo "Generated inventory:\n${inventoryContent}"
//       }
//     }
//   }
// }


// stage('Establish Passwordless SSH') {
//   steps {
//     dir('ansible') {
//       script {
//         // Generate public key from PEM if not present
//         sh '''
//           mkdir -p ~/.ssh
//           if [ ! -f "$PEM_FILE.pub" ]; then
//             ssh-keygen -y -f $PEM_FILE > $PEM_FILE.pub
//           fi
//         '''
//         def ips = readJSON text: env.EC2_IPS_JSON
//         ips.each { ip ->
//   // Wait for SSH to be available
//   sh """
//     for i in {1..30}; do
//       if ssh -o StrictHostKeyChecking=no -i $PEM_FILE -o ConnectTimeout=5 ubuntu@$ip 'echo SSH is up' 2>/dev/null; then
//         echo "SSH is ready on $ip"
//         break
//       fi
//       echo "Waiting for SSH on $ip..."
//       sleep 5
//     done
//   """
//   // Now copy the key
//   sh '''
//     ssh-keygen -R $ip || true
//     ssh-copy-id -i $PEM_FILE.pub -o StrictHostKeyChecking=no ubuntu@$ip
//   '''.replace('$ip', ip)
// }
//       }
//     }
//   }
// }

    stage('Run Ansible Playbook') {
      steps {
        dir('ansible') {
          sh 'ansible-playbook -i inventory.yaml playbook.yaml'
        }
      }
    }
  }
}
