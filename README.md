<h1>Objetivo</h1>
<p>Automatizar o provisionamento e configuração dos recursos a partir de um único script bash shell.</p>

</br>
<h1>Ferramentas</h1>

- Bash shell
- Terraform
- Ansible
- Nginx

</br>
<h1>Desafios</h1>

- Garantir o minimo de permissão possivel para atingir o objetivo por meio de regras de segurança na camada 3 e 4.

- Garantir que o Ansible acesse e configure os servidores na subrede privada a partir de um jumper, no caso, o servidor de Proxy e nunca diretamente.

- Criação do script de automação.

</br>
<h1>Arquitetura</h1>

![arch2](https://github.com/user-attachments/assets/95bcb45b-1121-4bea-9638-30b3b5d6f937)


- 1 vpc (192.168.0.0/24).
- 2 subredes (192.168.0.0/28 & 192.168.0.16/28).
- 1 internet gateway.
- 1 ipv4 elastíco público.
- 1 tabela de Roteamento.
- 4 instancias ec2 (proxy e 3 servidores http).
- 2 grupos de Segurança.

</br>
<h1>Grupos de Segurança e Tabelas de Roteamento</h1>

![sg](https://github.com/user-attachments/assets/de4aa2a6-2923-49e1-af59-5a5549b951a0)


</br>
<h1>Demo - Execução e cURL</h1>
<h3>Construindo e Configurando a Infraestrutura</h3>

[Demo-Terraformar.webm](https://github.com/user-attachments/assets/11e57d80-18de-40f5-80f8-28bccc8f4e6f)

</br>
<h1>Demo - Destruindo a Infraestrutura</h1>
<h3>Terraform Destroy</h3>

[Demo-Desterraformar.webm](https://github.com/user-attachments/assets/47814781-3d94-42bc-8d6c-cf22e3de83ab)


</br>
<h1>Demo - LB no Navegador</h1>

[Demo-Gui.webm](https://github.com/user-attachments/assets/b9dd9a23-6d60-4282-a059-77a5237fb3c5)


</br>
<h1>Nota</h1>
Os seguintes arquivos e caminhos são construídos a partir do script shell e estão contidos nesse repositório apenas para demonstração:
</br></br>

- /home/{user}/.ssh/config
- ./ansible/inventory.ini
- ./ansible/playbook.yml

Variaveis de ambiente AWS (client id e secret) foram exportadas na shell.
</br></br>
