# Prompt for Bastion Node's FQDN
read -p "Enter the Bastion Node's FQDN: " BASTION_HOST
while [[ -z "$BASTION_HOST" ]]; do
    read -p "Enter the Bastion Node's FQDN: " BASTION_HOST
    if [[ -z "$BASTION_HOST" ]]; then
        echo "FQDN cannot be empty. Please try again."
    fi
done

# Prompt for Bastion Node's Username
read -p "Enter the Bastion Node's Username: " USERNAME
while [[ -z "$USERNAME" ]]; do
    read -p "Enter the Bastion Node's Username: " USERNAME
    if [[ -z "$USERNAME" ]]; then
        echo "Username cannot be empty. Please try again."
    fi
done

# Prompt for Bastion Node's Password (silent input)
read -s -p "Enter the Bastion Node's Password: " PASSWORD
while [[ -z "$PASSWORD" ]]; do
    read -s -p "Enter the Bastion Node's Password: " PASSWORD
    echo  # Move to a new line after password input
    if [[ -z "$PASSWORD" ]]; then
        echo "Password cannot be empty. Please try again."
    fi
done

# Prompt for OCP API URL
read -p "Enter the OCP API URL: " OCP_API_URL
while [[ -z "$OCP_API_URL" ]]; do
    read -p "Enter the OCP API URL: " OCP_API_URL
    if [[ -z "$OCP_API_URL" ]]; then
        echo "OCP_API_URL cannot be empty. Please try again."
    fi
done

# Prompt for OCP Username
read -p "Enter the OCP Username: " OCP_USERNAME
while [[ -z "$OCP_USERNAME" ]]; do
    read -p "Enter the OCP Username: " OCP_USERNAME
    if [[ -z "$OCP_USERNAME" ]]; then
        echo "USERNAME cannot be empty. Please try again."
    fi
done

# Prompt for OCP PAssword
read -s -p "Enter the OCP Password: " OCP_PASSWORD
while [[ -z "$OCP_PASSWORD" ]]; do
    read -s -p "Enter the OCP Password: " OCP_PASSWORD
    if [[ -z "$OCP_PASSWORD" ]]; then
        echo "PASSWORD cannot be empty. Please try again."
    fi
done

read -p "Enter the AAP Console URL: " CONSOLE_URL
while [[ -z "$CONSOLE_URL" ]]; do
    read -p "Enter the AAP Controller URL: " CONSOLE_URL
    if [[ -z "$CONSOLE_URL" ]]; then
        echo "AAP CONSOLE URL cannot be empty. Please try again."
    fi
done
CONTROLLER_URL="$CONSOLE_URL/api/controller/v2"

read -p "Enter the AAP Username: " AAP_USERNAME
while [[ -z "$AAP_USERNAME" ]]; do
    read -p "Enter the Bastion Node's Username: " AAP_USERNAME
    if [[ -z "$AAP_USERNAME" ]]; then
        echo "Username cannot be empty. Please try again."
    fi
done

read -s -p "Enter the AAP Password: " AAP_PASSWORD
while [[ -z "$AAP_PASSWORD" ]]; do
    read -s -p "Enter the AAP Password: " AAP_PASSWORD
    echo
    if [[ -z "$AAP_PASSWORD" ]]; then
        echo "Password cannot be empty. Please try again."
    fi
done

# Prompt for GIT Token
read -p "Enter the GIT TOKEN of AIOPS Repo: " GIT_TOKEN

echo "export BASTION_HOST=\"$BASTION_HOST\"" > /root/aiops_ocp_demojam.env
echo "export USERNAME=\"$USERNAME\"" >> /root/aiops_ocp_demojam.env
echo "export PASSWORD=\"$PASSWORD\"" >> /root/aiops_ocp_demojam.env

echo "export OCP_API_URL=\"$OCP_API_URL\"" >> /root/aiops_ocp_demojam.env
echo "export OCP_USERNAME=\"$OCP_USERNAME\"" >> /root/aiops_ocp_demojam.env
echo "export OCP_PASSWORD=\"$OCP_PASSWORD\"" >> /root/aiops_ocp_demojam.env

echo "export GIT_TOKEN=\"$GIT_TOKEN\"" >> /root/aiops_ocp_demojam.env

echo "export CONSOLE_URL=\"$CONSOLE_URL\"" >> /root/aiops_ocp_demojam.env
echo "export CONTROLLER_URL=\"$CONTROLLER_URL\"" >> /root/aiops_ocp_demojam.env
echo "export AAP_USERNAME=\"$AAP_USERNAME\"" >> /root/aiops_ocp_demojam.env
echo "export AAP_PASSWORD=\"$AAP_PASSWORD\"" >> /root/aiops_ocp_demojam.env
