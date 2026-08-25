import { Column, CreateDateColumn, Entity, JoinColumn, ManyToOne, Unique } from 'typeorm';
import { BaseEntity } from './base.entity';
import { User } from './user.entity';

@Entity('auth_identities')
@Unique('uq_auth_identities_provider_identifier', ['provider', 'identifier'])
export class AuthIdentity extends BaseEntity {
  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'provider', type: 'text' })
  provider: string;

  @Column({ name: 'identifier', type: 'text' })
  identifier: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
