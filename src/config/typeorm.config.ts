import { TypeOrmModuleOptions } from '@nestjs/typeorm';

//docker run --rm   --name pg-docker -e POSTGRES_PASSWORD=test1234 -d -p 5432:5432 -v $HOME/docker/volumes/postgres:/var/lib/postgresql/data  postgres
import * as config from 'config';
const dbConfig: {
  type: 'postgres';
  host: string;
  port: number;
  username: string;
  password: string;
  database: string;
  synchronize: boolean;
} = config.get('db');

export const typeOrmConfig: TypeOrmModuleOptions = {
  type: dbConfig.type,
  host: process.env.RDS_HOSTNAME || dbConfig.host,
  port: +process.env.RDS_PORT || dbConfig.port,
  username: process.env.RDS_USERNAME || dbConfig.username,
  password: process.env.RDS_PASSWORD || dbConfig.password,
  database: process.env.RDS_DB_NAME || dbConfig.database,
  entities: [__dirname + '/../**/*.entity.{js,ts}'],
  synchronize: Boolean(process.env.TYPEORM_SYNC) || dbConfig.synchronize,
};
