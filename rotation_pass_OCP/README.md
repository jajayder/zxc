# aplic-user-password-rotation

Automação AAP/Ansible para descobrir `aplic-user-*` em Secrets Opaque de quatro clusters OpenShift DEV/HMG, consultar expiração no AD, trocar senhas com `ChangePassword` usando a senha atual capturada e atualizar somente `data.password` de todos os Secrets do mesmo usuário.

## Requisitos

- AAP com Execution Environment contendo:
  - `kubernetes.core`
  - `community.okd`
  - `community.general`
  - `ansible.windows`
  - Python Kubernetes client
- Host Windows `10.83.103.61` com acesso ao AD e módulo ActiveDirectory.
- AAP com credencial Windows/AD para conexão WinRM.
- Survey do Job Template com:
  - `ocp_user`
  - `ocp_pass`
- Os valores `ansible_user`/`ansible_password` devem vir da credencial do AAP, não do Git.
- SMTP acessível pelo Execution Environment.

## Survey

Recomendado:

```yaml
ocp_user: string
ocp_pass: string (senha)
```

Não salvar essas credenciais em `vars` do projeto.

## Regra de rotação

- `0..10` dias: troca automática.
- `< 0`: senha expirada, somente alerta.
- `> 10`: não altera.
- `PasswordNeverExpires=True`: ignora e alerta.
- Nenhuma senha dos Secrets válida no AD: `SENHA NÃO COMPATÍVEL`.

## Observação OpenShift

OpenShift normalmente usa OAuth2. Por isso o projeto usa `community.okd.openshift_auth` para transformar usuário/senha do Survey em token e usa esse token nas operações `kubernetes.core`.

## Segurança

Tasks que manipulam senhas/tokens usam `no_log: true`. O relatório nunca contém senha.

## Execução

```bash
ansible-galaxy collection install -r requirements.yml
ansible-playbook -i inventory/hosts.yml site.yml
```

No AAP, configure o Job Template para apontar para o projeto e forneça `ocp_user`/`ocp_pass` via Survey. A credencial Windows deve fornecer `ansible_user`/`ansible_password` para `10.83.103.61`.
