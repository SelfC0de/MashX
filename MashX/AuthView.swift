import SwiftUI

// MARK: - Root Auth Router
struct AuthRootView: View {
    @State private var screen: AuthScreen = .login

    enum AuthScreen { case login, register, recover }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            switch screen {
            case .login:    LoginView(onRegister: { screen = .register },
                                      onRecover:  { screen = .recover })
            case .register: RegisterView(onBack: { screen = .login })
            case .recover:  RecoverView(onBack: { screen = .login })
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: screen)
    }
}

// MARK: - LoginView
struct LoginView: View {
    var onRegister: () -> Void
    var onRecover:  () -> Void

    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var toast: ToastManager
    @State private var username = ""
    @State private var password = ""
    @State private var showPassword = false
    @FocusState private var focused: LoginField?
    private enum LoginField { case username, password }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                logoBlock
                Spacer().frame(height: 48)
                fieldsBlock
                Spacer().frame(height: 24)
                loginButton
                Spacer().frame(height: 16)
                recoverButton
                Spacer().frame(height: 40)
                registerRow
                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 28)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") { focused = nil }
                    .foregroundColor(Theme.accentChats).fontWeight(.semibold)
            }
        }
        .onChange(of: auth.errorMessage) { _, msg in
            if let msg { toast.show(msg, style: .error) }
        }
    }

    private var logoBlock: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Theme.accentProfile.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.accentProfile.opacity(0.3), lineWidth: 0.5))
                Text("MX")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Theme.accentProfile)
            }
            Text("MashX")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.text)
                .kerning(-0.5)
            Text("Войдите в аккаунт")
                .font(.system(size: 15))
                .foregroundColor(Theme.muted)
        }
    }

    private var fieldsBlock: some View {
        VStack(spacing: 12) {
            AuthField(
                icon: "at", placeholder: "Username",
                text: $username, focused: $focused, tag: .username,
                accentColor: Theme.accentChats
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            ZStack(alignment: .trailing) {
                AuthField(
                    icon: "lock.fill", placeholder: "Пароль",
                    text: $password, focused: $focused, tag: .password,
                    isSecure: !showPassword,
                    accentColor: Theme.accentChats
                )
                Button { showPassword.toggle() } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.muted)
                        .padding(.trailing, 16)
                }
            }
        }
    }

    private var loginButton: some View {
        Button {
            Task { await auth.login(username: username, password: password) }
        } label: {
            ZStack {
                if auth.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Войти")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(username.isEmpty || password.isEmpty ? Theme.dim : Theme.accentChats)
            .cornerRadius(14)
        }
        .disabled(username.isEmpty || password.isEmpty || auth.isLoading)
        .animation(.easeInOut(duration: 0.2), value: username.isEmpty || password.isEmpty)
    }

    private var recoverButton: some View {
        Button(action: onRecover) {
            Text("Забыли пароль?")
                .font(.system(size: 14))
                .foregroundColor(Theme.accentChats)
        }
    }

    private var registerRow: some View {
        HStack(spacing: 6) {
            Text("Нет аккаунта?")
                .font(.system(size: 14))
                .foregroundColor(Theme.muted)
            Button(action: onRegister) {
                Text("Зарегистрироваться")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.accentProfile)
            }
        }
    }
}

// MARK: - RegisterView
struct RegisterView: View {
    var onBack: () -> Void

    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var toast: ToastManager
    @State private var displayName = ""
    @State private var username    = ""
    @State private var password    = ""
    @State private var password2   = ""
    @State private var showPassword = false
    @State private var showRecovery = false
    @FocusState private var focused: RegField?
    private enum RegField { case name, username, pass, pass2 }

    private var isValid: Bool {
        !displayName.isEmpty && username.count >= 3 &&
        password.count >= 6 && password == password2
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)
                header
                Spacer().frame(height: 36)
                fields
                Spacer().frame(height: 8)
                passwordHint
                Spacer().frame(height: 24)
                registerButton
                Spacer().frame(height: 20)
                backRow
                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 28)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") { focused = nil }
                    .foregroundColor(Theme.accentProfile).fontWeight(.semibold)
            }
        }
        .onChange(of: auth.errorMessage) { _, msg in
            if let msg { toast.show(msg, style: .error) }
        }
        .sheet(isPresented: $showRecovery) {
            RecoveryCodeSheet(code: auth.recoveryCode ?? "")
        }
        .onChange(of: auth.state) { _, s in
            if s == .authenticated, auth.recoveryCode != nil {
                showRecovery = true
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Создать аккаунт")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(Theme.text)
            Text("Заполните данные для регистрации")
                .font(.system(size: 14))
                .foregroundColor(Theme.muted)
        }
    }

    private var fields: some View {
        VStack(spacing: 12) {
            AuthField(icon: "person.fill",    placeholder: "Имя",
                      text: $displayName, focused: $focused, tag: .name,
                      accentColor: Theme.accentProfile)

            AuthField(icon: "at",             placeholder: "Username (мин. 3 символа)",
                      text: $username, focused: $focused, tag: .username,
                      accentColor: Theme.accentProfile)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            ZStack(alignment: .trailing) {
                AuthField(icon: "lock.fill",   placeholder: "Пароль (мин. 6 символов)",
                          text: $password, focused: $focused, tag: .pass,
                          isSecure: !showPassword, accentColor: Theme.accentProfile)
                Button { showPassword.toggle() } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 14)).foregroundColor(Theme.muted)
                        .padding(.trailing, 16)
                }
            }

            AuthField(icon: "lock.shield.fill", placeholder: "Повторите пароль",
                      text: $password2, focused: $focused, tag: .pass2,
                      isSecure: !showPassword,
                      borderColor: password2.isEmpty ? nil : (password == password2 ? .green : .red),
                      accentColor: Theme.accentProfile)
        }
    }

    private var passwordHint: some View {
        HStack {
            if !password2.isEmpty && password != password2 {
                Image(systemName: "xmark.circle.fill").font(.system(size: 11)).foregroundColor(.red)
                Text("Пароли не совпадают").font(.system(size: 12)).foregroundColor(.red)
            }
            Spacer()
        }
    }

    private var registerButton: some View {
        Button {
            Task { await auth.register(username: username, displayName: displayName, password: password) }
        } label: {
            ZStack {
                if auth.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Зарегистрироваться")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(isValid ? Theme.accentProfile : Theme.dim)
            .cornerRadius(14)
        }
        .disabled(!isValid || auth.isLoading)
        .animation(.easeInOut(duration: 0.2), value: isValid)
    }

    private var backRow: some View {
        Button(action: onBack) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left").font(.system(size: 13))
                Text("Уже есть аккаунт")
            }
            .font(.system(size: 14))
            .foregroundColor(Theme.muted)
        }
    }
}

// MARK: - RecoverView
struct RecoverView: View {
    var onBack: () -> Void

    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var toast: ToastManager
    @State private var username    = ""
    @State private var code        = ""
    @State private var newPassword = ""
    @State private var step        = 1
    @State private var showNewCode = false
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                header
                Spacer().frame(height: 36)
                if step == 1 { stepOne }
                else          { stepTwo }
                Spacer().frame(height: 40)
                backRow
            }
            .padding(.horizontal, 28)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") { focused = false }
                    .foregroundColor(Theme.accentGroups).fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showNewCode) {
            RecoveryCodeSheet(code: auth.recoveryCode ?? "", isNew: true)
                .onDisappear { onBack() }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "key.fill")
                .font(.system(size: 36)).foregroundColor(Theme.accentGroups)
                .frame(width: 72, height: 72)
                .background(Theme.accentGroups.opacity(0.15))
                .cornerRadius(20)
            Text("Восстановление")
                .font(.system(size: 24, weight: .bold)).foregroundColor(Theme.text)
            Text(step == 1 ? "Введите username и резервный код" : "Придумайте новый пароль")
                .font(.system(size: 14)).foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
        }
    }

    private var stepOne: some View {
        VStack(spacing: 12) {
            authField("person.fill", "Username", $username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            authField("key.fill", "Резервный код (XXXX-XXXX-XXXX-XXXX)", $code)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()

            Button {
                guard !username.isEmpty && code.count >= 19 else {
                    toast.show("Заполните все поля", style: .warning)
                    return
                }
                withAnimation { step = 2 }
            } label: {
                Text("Продолжить")
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(Theme.accentGroups).cornerRadius(14)
            }
            .padding(.top, 8)
        }
    }

    private var stepTwo: some View {
        VStack(spacing: 12) {
            authField("lock.fill", "Новый пароль (мин. 6 символов)", $newPassword, secure: true)

            Button {
                Task {
                    let ok = await auth.recover(username: username, code: code, newPassword: newPassword)
                    if ok { showNewCode = true }
                }
            } label: {
                ZStack {
                    if auth.isLoading { ProgressView().tint(.white) }
                    else {
                        Text("Сменить пароль")
                            .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(newPassword.count >= 6 ? Theme.accentGroups : Theme.dim)
                .cornerRadius(14)
            }
            .disabled(newPassword.count < 6 || auth.isLoading)
            .padding(.top, 8)
        }
    }

    private var backRow: some View {
        Button(action: onBack) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left").font(.system(size: 13))
                Text("Назад")
            }
            .font(.system(size: 14)).foregroundColor(Theme.muted)
        }
    }

    private func authField(_ icon: String, _ ph: String, _ b: Binding<String>, secure: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14)).foregroundColor(Theme.accentGroups)
                .frame(width: 20)
            SwiftUI.Group {
                if secure {
                    SecureField(ph, text: b)
                } else {
                    TextField(ph, text: b)
                }
            }
            .font(.system(size: 15)).foregroundColor(Theme.text)
            .tint(Theme.accentGroups)
            .focused($focused)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Theme.card)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
    }
}

// MARK: - Recovery Code Sheet
struct RecoveryCodeSheet: View {
    let code: String
    var isNew: Bool = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var toast: ToastManager

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 24) {
                Capsule().fill(Theme.dim).frame(width: 36, height: 4).padding(.top, 10)

                Image(systemName: "key.shield.fill")
                    .font(.system(size: 40)).foregroundColor(Theme.accentGroups)
                    .frame(width: 80, height: 80)
                    .background(Theme.accentGroups.opacity(0.15))
                    .cornerRadius(20)

                VStack(spacing: 8) {
                    Text(isNew ? "Новый резервный код" : "Сохраните резервный код")
                        .font(.system(size: 20, weight: .bold)).foregroundColor(Theme.text)
                    Text("Это единственный способ восстановить пароль.\nСохраните код в надёжном месте.")
                        .font(.system(size: 14)).foregroundColor(Theme.muted)
                        .multilineTextAlignment(.center).padding(.horizontal, 20)
                }

                // Code display
                Text(code)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.accentGroups)
                    .padding(.horizontal, 24).padding(.vertical, 16)
                    .background(Theme.card)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.accentGroups.opacity(0.3), lineWidth: 0.5))

                Button {
                    UIPasteboard.general.string = code
                    toast.show("Код скопирован", style: .success)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.on.clipboard").font(.system(size: 14))
                        Text("Скопировать")
                    }
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.accentGroups)
                    .frame(maxWidth: .infinity).frame(height: 48)
                    .background(Theme.accentGroups.opacity(0.12))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.accentGroups.opacity(0.3), lineWidth: 0.5))
                }
                .padding(.horizontal, 32)

                Button {
                    dismiss()
                } label: {
                    Text("Я сохранил код")
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(Theme.accentGroups).cornerRadius(14)
                }
                .padding(.horizontal, 32)
                Spacer()
            }
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled()
    }
}

// MARK: - Reusable AuthField
struct AuthField<Tag: Hashable>: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var focused: FocusState<Tag?>.Binding
    let tag: Tag
    var isSecure: Bool = false
    var borderColor: Color? = nil
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(focused.wrappedValue == tag ? accentColor : Theme.muted)
                .frame(width: 20)
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.system(size: 15))
            .foregroundColor(Theme.text)
            .tint(accentColor)
            .focused(focused, equals: tag)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Theme.card)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    borderColor ?? (focused.wrappedValue == tag ? accentColor.opacity(0.5) : Theme.border),
                    lineWidth: 0.5
                )
        )
        .animation(.easeInOut(duration: 0.15), value: focused.wrappedValue == tag)
    }
}
