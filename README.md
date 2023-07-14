# Terraform + AWS + Github Actions

Este repositório tem como objetivo compartilhar o desenvolvimento de um ambiente na AWS com a utilização da ferramenta Terraform e para execução automatizada o Github Actions

## Terraform

Terraform é uma ferramenta para criar, alterar e criar versões de infraestrutura com segurança e eficiência. O Terraform pode ajudar com várias nuvens, tendo um único fluxo de trabalho para todas as nuvens. A infraestrutura gerenciada pelo Terraform pode ser hospedada em nuvens públicas, como Amazon Web Services, Microsoft Azure e Google Cloud Platform.
Seu objetivo é garantir que ambientes sejam reproduzíveis de uma maneira mais fácil possível, facilitação de de colaboração pois o arquivo pode ser compartilhado e entendido por todos do time. Para min o grande diferencial do terraform é criar uma estrutura que permita que você não esqueça uma configuração que é muito importante para sua infra.

## AWS - Configurando o Terraform para a AWS.

### Pré Requisitos.

1. Conhecimento básico AWS.
2. Na AWS é muito importante que você crie um usuário a partir do serviço IAM.
3. Esse usuário deve possuir permissão `AmazonEC2FullAccess`.
4. Após criado o usuário você precisa salvar o `ACCESS KEY ID` E `ACCESS SECURITY ID`, essas informações são necessários para o provider do terraform para a criação da infra.
5. Configuração do AWS CLI em sua máquina local para execução do terraform. [Link para instalação](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). Após instalar execute `aws configure` e adicione seu `ACCESS KEY ID` E `ACCESS SECURITY ID`.
6. Instalação do Terraform em sua máquina a partir do sie oficial do [HashCorp](https://developer.hashicorp.com/terraform/downloads)

### Configurando

1. Crie uma pasta para salvar os arquivos de configuração de sua infra, esses arquivos são:
    - main.tf: será usado para configurar sua infra;
    - provider.tf: será usado para armazenar sua ACCESS KEY, ACCESS SECURITY ID e a região que será criada sua infra;

2. No provider.tf adicione as seguintes informações:
```terraform
provider "aws" {
  region     = "us-east-2"
  access_key = "suaAccessKey"
  secret_key = "suaSecretId"
}
```

3. Agora no arquivo `main.tf` adicionamos iniciamente o data que é utilizado para criar a imagem da instância EC2

```terraform
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}
```
Aqui nessa estrutura é realizado uma busca na AWS por name e escolhe uma imagem linux própria da Amazon (amazon-linux-2) e com virtualização hvm.

Após a parte da imagem é criado um resource com nossa instancia EC2.

```terraform
resource "aws_instance" "terraform_githubactions" {
  ami                         = data.aws_ami.amazon-linux-2.id
  instance_type               = "t2.micro"
  key_name                    = "access"
  subnet_id                   = var.terraform_githubactions_subnet_public_id
  vpc_security_group_ids      = [aws_security_group.terraform_githubactions_ssh_http.id]
  associate_public_ip_address = true

  tags = {
    Name = "terraform-githubactions"
  }
}
```

Na camada da instância há uma informação importante que deve ser lembrada, para as instâncias é necessário ser criado uma chave para que acesse a imagem por SSH, essa chave é criado dentro da AWS, procurando o serviço EC2 e no menu ao lado com o nome KEY PAIRS, aqui você poderá criar uma chave o usuar uma que já existe. Realize o download da chave e deixe junto com a pasta que está sua `main.tf` e `provider.tf`.

- `ami`: utiliza o id que foi gerado a partir do data da AMI;
- `instance_type`: você especifica qual estrutura de armazenamento será usado;
- `key_name`: nome da chave para acesso que está na sua pasta do projeto;
- `subnet_id`: id da subnet que foi criada dentro da AWS (próxima versão do código será usado Data)
- `vpc_security_group_ids`: id da VPC que foi criada também dentro da AWS (próxima versão será usado o Data)
- `associate_public_ip_address`: campo booleano que você ativa para confirmar que sua instância será associada ao um endereço público
- `name`: por fim o nome da sua instancia.

```terraform
variable "terraform_githubactions_vpc_id" {
  default = "vpc_id_criado_na_AWS"
}

variable "terraform_githubactions_subnet_public_id" {
  default = "subnet_ID_criado_aws"
}
```

As duas váriáveis acima aponta para a subnet e vpc que foram criadas dentro da AWS. Para a segunda versão desse tutorial a VPC e Subnet serão criadas também pelo terraform a partir do comando Data

Por fim temos as configurações de *security group* que nós especificamos quais acessos nossa instância terá.

```terraform
resource "aws_security_group" "terraform_githubactions_ssh_http" {
  name        = "access_ssh"
  description = "Permite SSH e HTTP na instancia EC2"
  vpc_id      = var.terraform_githubactions_vpc_id

  ingress {
    description = "SSH to EC2"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP to EC2"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "access_ssh_e_http"
  }
}
```

Para esse tutorial foi liberado a porta SSH (22) e HTTP.

Após a criação do arquivo em sua máquina vamos inicializar o terraform e aplicar sua infra na AWS.

1. Execute o comando `terraform init` para inicializar o terraform no diretório com o `main.tf` e `provider.tf`;
2. Execute o comando `terraform plan` para que o terraform realize um pré-processamento e apresenta como sua infra ficara.
3. Execute `terraform apply` para criar a infra na AWS.

Após criar a Infra só brincar com sua instancia iniciada na AWS :) 

4. Quando terminar de utilizar sua instância basta executar o comando `terraform destroy` para desativar a instância na AWS.

## Github Actions

Abaixo segue a etapa de criação do Actions do Github.

Primeira etapa dentro do repositório do git, entre em configurações e procure no menu `Actions`, neste local você deve adicionar o `TF_USER_AWS_KEY` e `TF_USER_AWS_SECRET`.

Segunda etapa é criar uma pasta com o nome `.github/workflows`, após isso criar o arquivo `yaml` com o nome que deseja, aqui sendo `provision_ec2.yml`

Criado o arquivo vamos desenvolver o action.

```yaml
name: Provision EC2
on:
  workflow_dispatch:
    inputs:
      ec2-name:
        description: EC2 name
        required: true
        default: 'terraform-githubactions'
        type: string
```
Nesta primeira etapa é estrutura o nome do Action e qual a forma de ser executado, este sendo manual e adicionado uma variável com o nome `ec2-name` que é a váriavel string que se encontra dentro do arquivo `main.tf`, o valor dessa variável é o que está no atributo `default`.

Após essa etapa é criado os jobs que serão as ações no action.

```yaml
jobs:
  provision-ec2:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '14'
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: '${{ secrets.TF_USER_AWS_KEY }}'
          aws-secret-access-key: '${{ secrets.TF_USER_AWS_SECRET }}'
          aws-region: us-east-2
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_wrapper: false
      - name: Terraform Apply
        id:   apply
        env:
          TF_VAR_ec2_name:  "${{ github.event.inputs.ec2-name }}"
        run: |
          terraform init
          terraform validate
          terraform plan 
          terraform apply -auto-approve
```

Dentro do `step` primeiro é realizado o checkout do repositorio no action e configuração da versão 14 do node. Após essa configuração inicial é usado o action `aws-actions/configure-aws-credentials@v1` que é adicionado as informações de ACCESS KEY e ACCESS SECRET KEY que são os mesmos que estão no `provider.tf`.

Após ter adicionado as credenciais da AWS é feito a instalação do terraform e posteriormente na parte de `run` executado localmente no tutorial, `init`, `validate`, `plan`e `apply`.

**LEMBRETE**: É importante evitar de subir o arquivo `provider.tf` sendo esse com informações importantes de acesso, adicione esse arquivo no `.gitigone`.