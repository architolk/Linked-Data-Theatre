#Docker build instructions
A complete dockerfile is already part of the Linked Data Theatre. Make sure you have a recent docker installation ([www.docker.com](https://www.docker.com)), and procede by entering the following command:

	docker build -t {target}/{image name}:{tag}

Replace `{target}`, `{image name}` and `{tag}` with the appropriate names for your environment, for example:

	docker build -t architolk/ldt:v1.5.1

After building this image, you can run the image with the command:

	docker run -t architolk/ldt /run.sh
