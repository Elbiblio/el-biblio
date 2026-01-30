import { makeAutoObservable, runInAction } from 'mobx';
import { SignUpData } from '@/types';
import { AuthStore } from './AuthStore';
import { isValidEmail, isValidPasswordLength } from '@/utils/validation';

interface RegistrationState {
  formData: Omit<SignUpData, 'avatar'>;
  confirmPassword: string;
  showPassword: boolean;
  showConfirmPassword: boolean;
  error: string | null;
  showAvatarModal: boolean;
}

const initialState: RegistrationState = {
  formData: {
    email: '',
    password: '',
    first_name: '',
    last_name: '',
  },
  confirmPassword: '',
  showPassword: false,
  showConfirmPassword: false,
  error: null,
  showAvatarModal: false,
};

export class RegistrationStore {
  state = initialState;
  private authStore: AuthStore;

  constructor(authStore: AuthStore) {
    makeAutoObservable(this);
    this.authStore = authStore;
  }

  setFormField = <K extends keyof RegistrationState['formData']>(
    field: K,
    value: RegistrationState['formData'][K]
  ) => {
    this.state.formData[field] = value;
    this.state.error = null;
  };

  setConfirmPassword = (password: string) => {
    this.state.confirmPassword = password;
    this.state.error = null;
  };

  togglePasswordVisibility = () => {
    this.state.showPassword = !this.state.showPassword;
  };

  toggleConfirmPasswordVisibility = () => {
    this.state.showConfirmPassword = !this.state.showConfirmPassword;
  };

  validateForm = (): boolean => {
    const { email, password, first_name, last_name } = this.state.formData;
    const { confirmPassword } = this.state;
    if (!isValidEmail(email)) {
      this.state.error = 'Please enter a valid email address';
      return false;
    }
    if (!password || !isValidPasswordLength(password)) {
      this.state.error = 'Password must be at least 8 characters long';
      return false;
    }
    if (password !== confirmPassword) {
      this.state.error = 'Passwords do not match';
      return false;
    }
    if (!first_name.trim()) {
      this.state.error = 'First name is required';
      return false;
    }
    if (!last_name.trim()) {
      this.state.error = 'Last name is required';
      return false;
    }

    this.state.error = null;
    return true;
  };

  submit = () => {
    if (this.validateForm()) {
      runInAction(() => {
        this.state.showAvatarModal = true;
      });
    }
  };

  selectAvatar = async (avatarUrl: string): Promise<boolean> => {
    const success = await this.authStore.signUp({ ...this.state.formData, avatar: avatarUrl });
    runInAction(() => {
      this.state.showAvatarModal = false;
      if (!success) {
        this.state.error = this.authStore.error;
      }
    });
    return success;
  };

  closeAvatarModal = () => {
    this.state.showAvatarModal = false;
  };

  reset = () => {
    this.state = initialState;
  };
}

