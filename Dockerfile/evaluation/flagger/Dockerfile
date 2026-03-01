FROM mobinasri/flagger:v1.1.0

LABEL maintainer="Yoshitaka Sakamoto <yosakam2@gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive

ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /models
RUN wget https://raw.githubusercontent.com/mobinasri/flagger/refs/heads/main/misc/alpha_tsv/HiFi_DC_1.2/alpha_optimum_trunc_exp_gaussian_w_16000_n_50.HiFi_DC_1.2_DEC_2024.v1.1.0.tsv
RUN wget https://raw.githubusercontent.com/mobinasri/flagger/refs/heads/main/misc/alpha_tsv/ONT_R941_Guppy6.3.7/alpha_optimum_trunc_exp_gaussian_w_16000_n_50.ONT_R941_Guppy6.3.7_DEC_2024.v1.1.0.tsv
RUN wget https://raw.githubusercontent.com/mobinasri/flagger/refs/heads/main/misc/alpha_tsv/ONT_R1041_Dorado/alpha_optimum_trunc_exp_gaussian_w_8000_n_50.ONT_R1041_Dorado_DEC_2024.v1.1.0.tsv

CMD ["/bin/bash"]
