FROM ruby:3.2

# Instalar dependências do sistema
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs

# Definir diretório de trabalho no container
WORKDIR /myapp

# Copiar Gemfile e Gemfile.lock
COPY Gemfile* ./

# Instalar as gems
RUN bundle install

# Copiar o restante da aplicação
COPY . .

# Expor a porta 3000
EXPOSE 3000

# Configurar o ponto de entrada padrão
CMD CMD ["bash", "-c", "rm -f /myapp/tmp/pids/server.pid"]
