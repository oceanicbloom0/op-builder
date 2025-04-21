#!/bin/bash
set -uo pipefail

sudo snap install ttyd --classic
# ttyd -p 8000 bash

curl -fsSLO https://starship.rs/install.sh && sh ./install.sh --yes
rm ./install.sh
echo 'eval "$(starship init bash)"' >>/home/runner/.bashrc
echo 'eval "$(starship init bash)"' | sudo tee /root/.bashrc

mkdir -p /home/runner/.ssh
sudo mkdir -p /root/.ssh

# 1
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7a9wzWBmnjDtO39GZ0Z1wEGMkR1YRxeZkVNvPQ8GkZKHYdtCrqX+SdRBczo2xdJbHM9cDJNtOJKZp1/n4MCuMVMD8ea93npMjIXpt+lP7cGvyEYAhRrzKEiy3+jAVxnK9wDRpAGAI6uL5mLk9TAO3bt42Tzf02GGjgHqPshiVsBee2Y+rNqPWOb1a0gp302DlORo5stW4zLmRgvwEaxbcEr02lct4ly1s0fjjTJIxXHfOcs+tviW77IcXh1BeE+OvKLAHvfCalMnmm8q1WxDHk4feqCt/pq5pMWnvqg+PQlOLFT1Ff7T4Hi22shmy0Jbuor3HksxrdIcpl6hNAzeH" >>/home/runner/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7a9wzWBmnjDtO39GZ0Z1wEGMkR1YRxeZkVNvPQ8GkZKHYdtCrqX+SdRBczo2xdJbHM9cDJNtOJKZp1/n4MCuMVMD8ea93npMjIXpt+lP7cGvyEYAhRrzKEiy3+jAVxnK9wDRpAGAI6uL5mLk9TAO3bt42Tzf02GGjgHqPshiVsBee2Y+rNqPWOb1a0gp302DlORo5stW4zLmRgvwEaxbcEr02lct4ly1s0fjjTJIxXHfOcs+tviW77IcXh1BeE+OvKLAHvfCalMnmm8q1WxDHk4feqCt/pq5pMWnvqg+PQlOLFT1Ff7T4Hi22shmy0Jbuor3HksxrdIcpl6hNAzeH" | sudo tee /root/.ssh/authorized_ke
# 2
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpN4ZLZCLDnINMNIwRRkHgy90LtGTRbk/EEGk5q7skStUkTFAtm1IarT12qicZJozfDVciM9BpuYchH+bSVAdKCAo+kv1Z7xVqxpjmPwGRGXju3p5vucOIF2F8B58h6ddsyEzvcqiN4du+VBZsWJR+ZO6XCrZO0ejO+5aBloUfqCOSd/f3pp6PQ1Hw55pXvwMIDkj8kiDJcDa9NvbLrjgwJ2DEqihOC4MkCyr+CfZd5Tz5URmNf0aXUKWQJcQPDltngXa94MihE6PJCA/ftBkBVXtQBIa1fcO+Tx56Nsvlpu7GS7RgQ5EkkeVNmQ2VR50ZPme0G+SFrfsqElez2KyCuXCD/AcQl7rBmP5d6K9Z8aGnom8hVrJY7Mk3NYuPgkVRWfDm2uEEy5DpowfMwsdrrL4D6ml1nDvrIjXdcWqd21E4/aJGRmPcDWXb9cQy2J4LdYuaupjzLzPAv1x/wL7lUXtzjeoMNeIY9pZhAYMULZ0G58l4DqlC0fN3zqzAQA8=" >>/home/runner/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpN4ZLZCLDnINMNIwRRkHgy90LtGTRbk/EEGk5q7skStUkTFAtm1IarT12qicZJozfDVciM9BpuYchH+bSVAdKCAo+kv1Z7xVqxpjmPwGRGXju3p5vucOIF2F8B58h6ddsyEzvcqiN4du+VBZsWJR+ZO6XCrZO0ejO+5aBloUfqCOSd/f3pp6PQ1Hw55pXvwMIDkj8kiDJcDa9NvbLrjgwJ2DEqihOC4MkCyr+CfZd5Tz5URmNf0aXUKWQJcQPDltngXa94MihE6PJCA/ftBkBVXtQBIa1fcO+Tx56Nsvlpu7GS7RgQ5EkkeVNmQ2VR50ZPme0G+SFrfsqElez2KyCuXCD/AcQl7rBmP5d6K9Z8aGnom8hVrJY7Mk3NYuPgkVRWfDm2uEEy5DpowfMwsdrrL4D6ml1nDvrIjXdcWqd21E4/aJGRmPcDWXb9cQy2J4LdYuaupjzLzPAv1x/wL7lUXtzjeoMNeIY9pZhAYMULZ0G58l4DqlC0fN3zqzAQA8=" | sudo tee /root/.ssh/authorized_ke

docker run --net=host cloudflare/cloudflared:latest tunnel --no-autoupdate run --token $CLOUDFLARED_TOKEN

# 运行后续任务
echo "[SSH] 继续运行后续任务..."