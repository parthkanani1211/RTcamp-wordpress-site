# RTcamp-wordpress-site


# Clone my GitHub repository by following command
git clone  git clone https://github.com/parthkanani1211/RTcamp-wordpress-site.git

# Make (wordpress-script.sh) file executable by following command
chmod +x wordpress-script.sh

# Then, you can run the script to create a WordPress site by providing the site name as a command-line argument by following command
./wordpress-script.sh example.com

# After the site is created, you can use the following subcommands:
To start the containers: ./wordpress-script.sh example.com start

To stop the containers: ./wordpress-script.sh example.com stop

To delete the site: ./wordpress-script.sh example.com delete
