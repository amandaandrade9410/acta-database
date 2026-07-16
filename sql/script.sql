-- Criando schemas
CREATE SCHEMA IF NOT EXISTS public;
CREATE SCHEMA IF NOT EXISTS pdca;
CREATE SCHEMA IF NOT EXISTS auditoria;
 
-- Schema Public
CREATE TABLE IF NOT EXISTS empresa (
    id BIGSERIAL PRIMARY KEY,
    cnpj CHAR(14) NOT NULL UNIQUE CHECK (cnpj ~ '^[0-9]{14}$'),
    nome VARCHAR(160) NOT NULL CHECK (LENGTH(TRIM(nome)) >= 2),
    tamanho_empresa VARCHAR(40) NOT NULL CHECK (tamanho_empresa IN ('PEQUENA', 'MEDIA', 'GRANDE')),
    setor_empresa VARCHAR(100) NOT NULL,
    status VARCHAR(40) NOT NULL CHECK (status IN ('ATIVO', 'INATIVO', 'PENDENTE', 'BLOQUEADO', 'ARQUIVADO')),
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ
);
 
CREATE TABLE IF NOT EXISTS usuario_sistema (
    id BIGSERIAL PRIMARY KEY,
    id_empresa BIGINT NOT NULL REFERENCES empresa(id) ON DELETE CASCADE,
    nome VARCHAR(160) NOT NULL,
    email_login VARCHAR(254) NOT NULL UNIQUE CHECK (email_login ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'),
    senha_hash VARCHAR(255) NOT NULL,
    tipo_usuario VARCHAR(40) NOT NULL CHECK (tipo_usuario IN ('ADMIN', 'GESTOR', 'COLABORADOR')),
    status VARCHAR(40) NOT NULL CHECK (status IN ('ATIVO', 'INATIVO', 'PENDENTE', 'BLOQUEADO', 'ARQUIVADO')),
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ
);
 
CREATE TABLE IF NOT EXISTS colaborador (
    id BIGSERIAL PRIMARY KEY,
    id_empresa BIGINT NOT NULL REFERENCES empresa(id) ON DELETE CASCADE,
    id_usuario BIGINT NOT NULL UNIQUE REFERENCES usuario_sistema(id) ON DELETE CASCADE,
    cpf CHAR(11) NOT NULL UNIQUE CHECK (cpf ~ '^[0-9]{11}$'),
    nome VARCHAR(160) NOT NULL,
    cargo VARCHAR(100) NOT NULL,
    area VARCHAR(100) NOT NULL,
    data_nascimento DATE NOT NULL CHECK(data_nascimento <= CURRENT_DATE - INTERVAL '18 years'),
    data_contratacao DATE NOT NULL,
    permissao_gestor BOOLEAN NOT NULL,
    status VARCHAR(40) NOT NULL CHECK (status IN ('ATIVO', 'INATIVO', 'PENDENTE', 'BLOQUEADO', 'ARQUIVADO')),
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ,
    CONSTRAINT colaborador_datas_check CHECK (data_contratacao >= data_nascimento)
);
 
CREATE TABLE IF NOT EXISTS endereco_empresa (
    id BIGSERIAL PRIMARY KEY,
    id_empresa BIGINT NOT NULL REFERENCES empresa(id) ON DELETE CASCADE,
    cep CHAR(8) NOT NULL CHECK (cep ~ '^[0-9]{8}$'),
    uf CHAR(2) NOT NULL CHECK (uf ~ '^[A-Z]{2}$'),
    cidade VARCHAR(100) NOT NULL,
    bairro VARCHAR(100) NOT NULL,
    logradouro VARCHAR(180) NOT NULL,
    numero_endereco VARCHAR(20) NOT NULL,
    complemento TEXT,
    principal BOOLEAN NOT NULL,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ
);
 
CREATE TABLE IF NOT EXISTS email_empresa (
    id BIGSERIAL PRIMARY KEY,
    id_empresa BIGINT NOT NULL REFERENCES empresa(id) ON DELETE CASCADE,
    email VARCHAR(254) NOT NULL CHECK (email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'),
    principal BOOLEAN NOT NULL,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT email_empresa_unique_0 UNIQUE (id_empresa, email)
);
 
CREATE TABLE IF NOT EXISTS telefone_empresa (
    id BIGSERIAL PRIMARY KEY,
    id_empresa BIGINT NOT NULL REFERENCES empresa(id) ON DELETE CASCADE,
    numero_telefone VARCHAR(20) NOT NULL CHECK (numero_telefone ~ '^[0-9]{10,15}$'),
    principal BOOLEAN NOT NULL,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT telefone_empresa_unique_0 UNIQUE (id_empresa, numero_telefone)
);
 
CREATE TABLE IF NOT EXISTS email_colaborador (
    id BIGSERIAL PRIMARY KEY,
    id_colaborador BIGINT NOT NULL REFERENCES colaborador(id) ON DELETE CASCADE,
    email VARCHAR(254) NOT NULL CHECK (email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'),
    principal BOOLEAN NOT NULL,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT email_colaborador_unique_0 UNIQUE (id_colaborador, email)
);
 
CREATE TABLE IF NOT EXISTS telefone_colaborador (
    id BIGSERIAL PRIMARY KEY,
    id_colaborador BIGINT NOT NULL REFERENCES colaborador(id) ON DELETE CASCADE,
    numero_telefone VARCHAR(20) NOT NULL CHECK (numero_telefone ~ '^[0-9]{10,15}$'),
    principal BOOLEAN NOT NULL,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT telefone_colaborador_unique_0 UNIQUE (id_colaborador, numero_telefone)
);
 
-- Schema PDCA
CREATE TABLE IF NOT EXISTS pdca.ciclo (
    id BIGSERIAL PRIMARY KEY,
    id_empresa BIGINT NOT NULL REFERENCES empresa(id) ON DELETE CASCADE,
    id_responsavel BIGINT NOT NULL REFERENCES usuario_sistema(id),
    id_ishikawa_mongo INTEGER,
    titulo VARCHAR(160) NOT NULL,
    descricao TEXT NOT NULL,
    status VARCHAR(40) NOT NULL CHECK (status IN ('PLANEJAMENTO', 'EXECUCAO', 'VERIFICACAO', 'PADRONIZACAO', 'CONCLUIDO', 'CANCELADO', 'PAUSADO')),
    data_inicio DATE NOT NULL,
    data_estimada_fim DATE NOT NULL,
    data_fim_real DATE,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ,
    CONSTRAINT ciclo_datas_check CHECK (data_estimada_fim >= data_inicio AND (data_fim_real IS NULL OR data_fim_real >= data_inicio))
);

CREATE TABLE IF NOT EXISTS pdca.plano_acao (
    id BIGSERIAL PRIMARY KEY,
    id_ciclo BIGINT NOT NULL REFERENCES pdca.ciclo(id) ON DELETE CASCADE,
    nome VARCHAR(160) NOT NULL,
    objetivo TEXT,
    prioridade VARCHAR(40) NOT NULL CHECK (prioridade IN ('BAIXA', 'MEDIA', 'ALTA', 'CRITICA')),
    status VARCHAR(40) NOT NULL CHECK (status IN ('RASCUNHO', 'APROVADO', 'EM_EXECUCAO', 'CONCLUIDO', 'CANCELADO')),
    origem VARCHAR(40) NOT NULL CHECK (origem IN ('MANUAL', 'IA', 'FORMULARIO', 'IMPORTACAO', 'SISTEMA')),
    criado_por BIGINT NOT NULL REFERENCES usuario_sistema(id),
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ
);
 
CREATE TABLE IF NOT EXISTS pdca.meta (
    id BIGSERIAL PRIMARY KEY,
    id_ciclo BIGINT NOT NULL REFERENCES pdca.ciclo(id) ON DELETE CASCADE,
    id_plano_acao BIGINT NOT NULL REFERENCES pdca.plano_acao(id),
    objetivo TEXT NOT NULL,
    valor_base NUMERIC(15,2) CHECK (valor_base >= 0),
    valor_alvo NUMERIC(15,2) CHECK (valor_alvo >= 0),
    unidade VARCHAR(30),
    prazo DATE NOT NULL,
    status VARCHAR(40) NOT NULL CHECK (status IN ('NAO_INICIADA', 'EM_ANDAMENTO', 'ATINGIDA', 'PARCIALMENTE_ATINGIDA', 'NAO_ATINGIDA', 'CANCELADA')),
    prioridade VARCHAR(40) NOT NULL CHECK (prioridade IN ('BAIXA', 'MEDIA', 'ALTA', 'CRITICA')),
    area VARCHAR(100),
    categoria VARCHAR(100),
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ
);
 
 
CREATE TABLE IF NOT EXISTS pdca.treinamento (
    id BIGSERIAL PRIMARY KEY,
    id_ciclo BIGINT NOT NULL REFERENCES pdca.ciclo(id) ON DELETE CASCADE,
    id_anexo_mongo INTEGER,
    id_responsavel BIGINT NOT NULL REFERENCES usuario_sistema(id),
    titulo VARCHAR(160) NOT NULL,
    descricao TEXT,
    data_treinamento DATE NOT NULL,
    obrigatorio BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ
);
 
CREATE TABLE IF NOT EXISTS pdca.verificacao_resultado (
    id BIGSERIAL PRIMARY KEY,
    id_ciclo BIGINT NOT NULL REFERENCES pdca.ciclo(id) ON DELETE CASCADE,
    criado_por BIGINT NOT NULL REFERENCES usuario_sistema(id),
    status VARCHAR(40) NOT NULL CHECK (status IN ('NAO_VERIFICADO', 'APROVADO', 'PARCIAL', 'REPROVADO')),
    resumo TEXT NOT NULL,
    observacao TEXT,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS pdca.problema (
    id BIGSERIAL PRIMARY KEY,
    id_ciclo BIGINT NOT NULL REFERENCES pdca.ciclo(id) ON DELETE CASCADE,
    id_problema_pai BIGINT REFERENCES pdca.problema(id) ON DELETE CASCADE,
    criado_por BIGINT NOT NULL REFERENCES usuario_sistema(id),
    titulo VARCHAR(160) NOT NULL,
    descricao TEXT NOT NULL,
    peso NUMERIC(3,2) NOT NULL CHECK (peso BETWEEN 0 AND 1),
    status VARCHAR(40) NOT NULL CHECK (status IN ('ABERTO', 'EM_ANALISE', 'PRIORIZADO', 'RESOLVIDO', 'DESCARTADO')),
    origem VARCHAR(40) NOT NULL CHECK (origem IN ('MANUAL', 'IA', 'FORMULARIO', 'IMPORTACAO', 'SISTEMA')),
    persistente BOOLEAN NOT NULL DEFAULT FALSE,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ
);
 
CREATE TABLE IF NOT EXISTS pdca.causa_raiz (
    id BIGSERIAL PRIMARY KEY,
    id_ciclo BIGINT NOT NULL REFERENCES pdca.ciclo(id) ON DELETE CASCADE,
    id_problema BIGINT NOT NULL REFERENCES pdca.problema(id),
    id_plano_acao BIGINT REFERENCES pdca.plano_acao(id),
    id_5_porques_mongo INTEGER,
    validada_por BIGINT REFERENCES usuario_sistema(id),
    descricao TEXT NOT NULL,
    origem VARCHAR(40) NOT NULL CHECK (origem IN ('MANUAL', 'IA', 'FORMULARIO', 'IMPORTACAO', 'SISTEMA')),
    aceita BOOLEAN NOT NULL,
    validada_em TIMESTAMPTZ,
    principal BOOLEAN NOT NULL,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ
);
 
CREATE TABLE IF NOT EXISTS pdca.meta_responsavel (
    id_meta BIGINT NOT NULL REFERENCES pdca.meta(id) ON DELETE CASCADE,
    id_usuario BIGINT NOT NULL REFERENCES usuario_sistema(id) ON DELETE CASCADE,
    PRIMARY KEY (id_meta, id_usuario)
);
 
CREATE TABLE IF NOT EXISTS pdca.plano_5w2h (
    id BIGSERIAL PRIMARY KEY,
    id_plano_acao BIGINT NOT NULL UNIQUE REFERENCES pdca.plano_acao(id) ON DELETE CASCADE,
    id_who_responsavel BIGINT NOT NULL REFERENCES usuario_sistema(id),
    what_acao TEXT NOT NULL,
    why_justificativa TEXT NOT NULL,
    where_local TEXT NOT NULL,
    when_inicio DATE,
    when_fim DATE NOT NULL,
    how_modo_execucao TEXT NOT NULL,
    how_much_custo NUMERIC(12,2) NOT NULL CHECK (how_much_custo >= 0),
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ,
    CONSTRAINT plano_5w2h_datas_check CHECK (when_inicio IS NULL OR when_fim >= when_inicio)
);
 
CREATE TABLE IF NOT EXISTS pdca.efeito_secundario (
    id BIGSERIAL PRIMARY KEY,
    id_verificacao_resultado BIGINT NOT NULL REFERENCES pdca.verificacao_resultado(id) ON DELETE CASCADE,
    descricao TEXT NOT NULL,
    peso NUMERIC(3,2) NOT NULL CHECK (peso BETWEEN 0 AND 1),
    impacto_estimado TEXT,
    tipo VARCHAR(8) CHECK (tipo IN ('POSITIVO', 'NEGATIVO')),
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ
);
 
CREATE TABLE IF NOT EXISTS pdca.tarefa (
    id BIGSERIAL PRIMARY KEY,
    id_plano_acao BIGINT NOT NULL REFERENCES pdca.plano_acao(id) ON DELETE CASCADE,
    id_responsavel BIGINT NOT NULL REFERENCES usuario_sistema(id),
    titulo VARCHAR(160) NOT NULL,
    descricao TEXT NOT NULL,
    prioridade VARCHAR(40) NOT NULL CHECK (prioridade IN ('BAIXA', 'MEDIA', 'ALTA', 'CRITICA')),
    status VARCHAR(40) NOT NULL CHECK (status IN ('PENDENTE', 'EM_ANDAMENTO', 'BLOQUEADA', 'CONCLUIDA', 'ATRASADA', 'CANCELADA')),
    data_inicio_real DATE,
    data_fim_prevista DATE NOT NULL,
    data_fim_real DATE,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ,
    CONSTRAINT tarefa_datas_check CHECK ((data_inicio_real IS NULL OR data_fim_prevista >= data_inicio_real) AND (data_fim_real IS NULL OR data_inicio_real IS NULL OR data_fim_real >= data_inicio_real))
);
 
 
CREATE TABLE IF NOT EXISTS pdca.alerta_prazo (
    id BIGSERIAL PRIMARY KEY,
    id_tarefa BIGINT NOT NULL REFERENCES pdca.tarefa(id) ON DELETE CASCADE,
    id_usuario_destino BIGINT NOT NULL REFERENCES usuario_sistema(id) ON DELETE CASCADE,
    mensagem TEXT NOT NULL,
    enviado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    lido_em TIMESTAMPTZ
);
 
CREATE TABLE IF NOT EXISTS pdca.tarefa_dependencia (
    id_tarefa BIGINT NOT NULL REFERENCES pdca.tarefa(id) ON DELETE CASCADE,
    id_tarefa_dependencia BIGINT NOT NULL REFERENCES pdca.tarefa(id) ON DELETE CASCADE,
    PRIMARY KEY(id_tarefa, id_tarefa_dependencia),
    CONSTRAINT tarefa_dependencia_diferente_check CHECK (id_tarefa <> id_tarefa_dependencia)
);
 
CREATE TABLE IF NOT EXISTS pdca.usuario_ciclo (
    id_usuario BIGINT NOT NULL REFERENCES usuario_sistema(id) ON DELETE CASCADE,
    id_ciclo BIGINT NOT NULL REFERENCES pdca.ciclo(id) ON DELETE CASCADE,
    papel_ciclo VARCHAR(40) NOT NULL CHECK (papel_ciclo IN ('RESPONSAVEL', 'PARTICIPANTE', 'EXECUTOR', 'VALIDADOR', 'OBSERVADOR')),
    PRIMARY KEY (id_usuario, id_ciclo)
);
 
CREATE TABLE IF NOT EXISTS pdca.usuario_treinamento (
    id_treinamento BIGINT NOT NULL REFERENCES pdca.treinamento(id) ON DELETE CASCADE,
    id_usuario BIGINT NOT NULL REFERENCES usuario_sistema(id) ON DELETE CASCADE,
    obrigatorio BOOLEAN NOT NULL,
    status VARCHAR(40) NOT NULL CHECK (status IN ('PENDENTE', 'CONFIRMADO', 'CONCLUIDO', 'DISPENSADO', 'CANCELADO')),
    terminado_em TIMESTAMPTZ,
    PRIMARY KEY (id_usuario, id_treinamento)
);
 
CREATE TABLE IF NOT EXISTS pdca.priorizacao_problema_usuario (
    id_problema BIGINT NOT NULL REFERENCES pdca.problema(id) ON DELETE CASCADE,
    id_usuario BIGINT NOT NULL REFERENCES usuario_sistema(id) ON DELETE CASCADE,
    posicao INTEGER NOT NULL CHECK (posicao > 0),
    peso_calculado NUMERIC(3,2) NOT NULL CHECK (peso_calculado BETWEEN 0 AND 1),
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ,
    PRIMARY KEY (id_problema, id_usuario)
);
 
-- Schema auditoria
CREATE TABLE IF NOT EXISTS auditoria.catalogo_dados (
    id BIGSERIAL PRIMARY KEY,
    nome_schema VARCHAR(100) NOT NULL,
    tabela VARCHAR(100) NOT NULL,
    coluna VARCHAR(100) NOT NULL,
    tipo_dado VARCHAR(80) NOT NULL,
    eh_pk BOOLEAN NOT NULL,
    eh_fk BOOLEAN NOT NULL,
    referencia TEXT,
    obrigatorio BOOLEAN NOT NULL,
    regra_negocio TEXT,
    nivel_acesso VARCHAR(40) NOT NULL CHECK (nivel_acesso IN ('PUBLICO', 'INTERNO', 'RESTRITO', 'SENSIVEL')),
    observacao TEXT,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT catalogo_dados_unique_0 UNIQUE (tabela, coluna)
);
 
CREATE TABLE IF NOT EXISTS auditoria.atv_usuario_dia (
    id BIGSERIAL PRIMARY KEY,
    id_usuario BIGINT REFERENCES usuario_sistema(id) ON DELETE CASCADE,
    data_atv DATE,
    hora_inicio TIMESTAMPTZ NOT NULL,
    hora_fim TIMESTAMPTZ NOT NULL,
    qnt_acoes INTEGER NOT NULL CHECK (qnt_acoes >= 0),
    CONSTRAINT atv_usuario_dia_horario_check CHECK (hora_fim >= hora_inicio)
);
 
CREATE TABLE IF NOT EXISTS auditoria.log_auditoria (
    id BIGSERIAL PRIMARY KEY,
    id_usuario BIGINT REFERENCES usuario_sistema(id),
    id_registro BIGINT NOT NULL,
    tabela VARCHAR(100) NOT NULL,
    operacao VARCHAR(40) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT', 'READ', 'EXPORT')),
    dados_antes JSONB NOT NULL,
    dados_depois JSONB NOT NULL,
    data_log TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT log_auditoria_json_check CHECK (jsonb_typeof(dados_antes) = 'object' AND jsonb_typeof(dados_depois) = 'object')
);
 
CREATE TABLE IF NOT EXISTS auditoria.log_status (
    id BIGSERIAL PRIMARY KEY,
    id_usuario BIGINT NOT NULL REFERENCES usuario_sistema(id) ON DELETE CASCADE,
    id_registro BIGINT NOT NULL,
    tabela VARCHAR(100) NOT NULL,
    status_anterior VARCHAR(40) NOT NULL,
    status_atual VARCHAR(40) NOT NULL,
    data_log TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
 
CREATE TABLE IF NOT EXISTS auditoria.log_colaborador (
    id BIGSERIAL PRIMARY KEY,
    id_colaborador BIGINT NOT NULL REFERENCES colaborador(id),
    id_usuario BIGINT NOT NULL REFERENCES usuario_sistema(id),
    operacao VARCHAR(40) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT', 'READ', 'EXPORT')),
    dados_antes JSONB NOT NULL,
    dados_depois JSONB NOT NULL,
    data_log TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT log_colaborador_json_check CHECK (jsonb_typeof(dados_antes) = 'object' AND jsonb_typeof(dados_depois) = 'object')
);
 
CREATE TABLE IF NOT EXISTS auditoria.log_acesso_usuario (
    id BIGSERIAL PRIMARY KEY,
    id_usuario BIGINT NOT NULL REFERENCES usuario_sistema(id) ON DELETE CASCADE,
    id_ciclo BIGINT REFERENCES pdca.ciclo(id) ON DELETE CASCADE,
    acao_realizada VARCHAR(60) NOT NULL,
    acessado_em TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
 
CREATE TABLE IF NOT EXISTS auditoria.log_tarefa (
    id BIGSERIAL PRIMARY KEY,
    id_tarefa BIGINT NOT NULL REFERENCES pdca.tarefa(id),
    id_usuario BIGINT NOT NULL REFERENCES usuario_sistema(id),
    dados_antes JSONB NOT NULL,
    dados_depois JSONB NOT NULL,
    data_log TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    operacao VARCHAR(40) NOT NULL CHECK (operacao IN ('INSERT', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT', 'READ', 'EXPORT')),
    CONSTRAINT log_tarefa_json_check CHECK (jsonb_typeof(dados_antes) = 'object' AND jsonb_typeof(dados_depois) = 'object')
);