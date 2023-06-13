#!/bin/bash

# Function to check if a command is available
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check if Docker is installed, and install if missing
if ! command_exists docker; then
  echo "Docker not found. Installing Docker..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  sudo usermod -aG docker "$USER"
  rm get-docker.sh
  echo "Docker installation complete."
fi

# Check if Docker Compose is installed, and install if missing
if ! command_exists docker-compose; then
  echo "Docker Compose not found. Installing Docker Compose..."
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  echo "Docker Compose installation complete."
fi

# Check if site name is provided as a command-line argument
if [ $# -eq 0 ]; then
  echo "Please provide a site name as a command-line argument."
  exit 1
fi

# Set the site name
site_name=$1

# Create the docker-compose.yml file
cat > docker-compose.yml <<EOF
version: '3'
services:
  db:
    image: mysql:5.7
    volumes:
      - db_data:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: example_root_password
      MYSQL_DATABASE: example_db
      MYSQL_USER: example_user
      MYSQL_PASSWORD: example_password
  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    volumes:
      - ./wp:/var/www/html
    ports:
      - 80:80
    restart: always
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: example_user
      WORDPRESS_DB_PASSWORD: example_password
      WORDPRESS_DB_NAME: example_db
volumes:
  db_data:
EOF

# Create the wp directory
mkdir wp

# Create the nginx.conf file
cat > wp/nginx.conf <<EOF
server {
    listen 80;
    server_name $site_name;

    root /var/www/html;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF

# Create the Docker network
docker network create wordpress

# Start the containers
docker-compose up -d

# Add an entry in /etc/hosts
sudo -- sh -c "echo '127.0.0.1 $site_name' >> /etc/hosts"

# Prompt the user to open the site in a browser
echo "The site has been created successfully. You can now open http://$site_name in your browser."

# Function to stop and remove the containers
stop_and_remove_containers() {
  docker-compose down
  docker network rm wordpress
}

# Function to delete the site
delete_site() {
  stop_and_remove_containers
  rm -rf wp
  sudo sed -i "/$site_name/d" /etc/hosts
  echo "The site has been deleted."
}

# Check if subcommand is provided
if [ $# -eq 2 ]; then
  subcommand=$2
  case $subcommand in
    start)
      docker-compose up -d
      echo "The site has been started."
      ;;
    stop)
      docker-compose stop
      echo "The site has been stopped."
      ;;
    delete)
      delete_site
      ;;
    *)
      echo "Invalid subcommand. Available subcommands: start, stop, delete."
      exit 1
      ;;
  esac
fi
