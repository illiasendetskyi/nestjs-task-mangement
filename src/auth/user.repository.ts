import { Repository, EntityRepository } from 'typeorm';
import { User } from './user.entity';
import { AuthCredentialsDto } from './dto/auth-credentials.dto';
import { ConflictException, InternalServerErrorException } from '@nestjs/common';

@EntityRepository(User)
export class UserRepository extends Repository<User> {
  async signUp(authCredentialsDto: AuthCredentialsDto): Promise<void> {
    const { username, password } = authCredentialsDto;

    const user = new User();
    user.username = username;
    user.password = password;
    try {
      await user.save();
    } catch (error) {
      console.log(error);
      //TODO: move to the enums
      //dup of user name
      if (error.code === '23505') {
        throw new ConflictException(`Username "${username}" already exists`);
      } else {
        throw new InternalServerErrorException();
      }
    }
  }
}
