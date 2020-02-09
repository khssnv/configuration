{ pkgs, ... }:

let
  home-manager = builtins.fetchGit {
    url = "https://github.com/rycee/home-manager.git";
    rev = "f5c9303cedd67a57121f0cbe69b585fb74ba82d9";
    ref = "release-19.09";
  };
  vim_custom = pkgs.vim_configurable.override {
    python = pkgs.python36Full;
  };

in
{
  imports = [
      (import "${home-manager}/nixos")
  ];

  users.extraUsers.khassanov = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/khassanov";
    description = "Alisher A. Khassanov";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
    # openssh.authorizedKeys.keys = import ./keys.nix;
  };

  home-manager.users.khassanov = {
    home.packages = [
      vim_custom
      pkgs.tmux
      pkgs.ncdu
    ];
    programs = {
      home-manager.enable = true;
      git = {
        enable = true;
        userName = "Alisher A. Khassanov";
        userEmail = "a.khssnv@gmail.com";
      };
      zsh = {
        enable = true;
        # enableCompletion = true;
        # syntaxHighlighting.enable = true;
        # enableAutosuggestions.enable = true;
        oh-my-zsh = {
          enable = true;
          theme = "bira";
          plugins = [ "git" ];
        };
      };
    };
  };

  users.extraUsers.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLB7lnUc9iy4UYdAl5q2qmrB1VEuRMcucluAe6WFpYV khassanov@32vd"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/FL9uTGxLKKVeMe1O2PSTzOgu23hRoHe4GA2hNreYo6lwkSO9T6GU2iU4nq9HHBLTN1uBe9ttp61QYiAuddyOWss9zkcu1WU5gMOXmBqFZPj69C/BpOzQZecq1P7AkKIu7esq+fe6ANKMinGJVQhrsrknwYVLznp8OfxIHzq6PLJADI8GZBBGq4hy4AsLbGZqt1jK8aDWoUrwSt+5QdQjMLxaljFNxonacmqoMa391V2vncN+npaQETI2nNxoXeLcPy0Yt0oPJccU9oYQh+fg52jSI3yXR8+fhDQyQLKVHHpYtH88wBSu4/fiwRWRAqRJYZg7AYAluEwNFePWnIH/UP1cUbiteWDKvwAoaaXKvGO5mBNi79G+Y42xv72RdHSIiBpvp4zuUCC5bt87k1QwjHeKGVhNMR2ba2Xz4AoJEw7VnCu8R8K6nif6LEr1kbIgmzM+LefnDggzONF5K7IGoMzjMfTJpdLDO3+MJiBsTW471HXgw2UzZKR2gpcHFkf3GcLsOcIOE9lqoDoFHvwpR8IhnK42qdV+m6VaXoWeSEjZEE99vqVNKyWHDAB4MZxNOrwIYSqnHExoNE8UixUYeL2F3Qv3Onjfg4sjDZVA+r0xjO97qm6IDk9NbWmna8E7vZGEh4GPTdHPwfFZHfJL3p8kFNh7AfZHSy1qrtXttw== a.khssnv@gmail.com"
  ];

  users.extraUsers.khassanov.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLB7lnUc9iy4UYdAl5q2qmrB1VEuRMcucluAe6WFpYV khassanov@32vd"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/FL9uTGxLKKVeMe1O2PSTzOgu23hRoHe4GA2hNreYo6lwkSO9T6GU2iU4nq9HHBLTN1uBe9ttp61QYiAuddyOWss9zkcu1WU5gMOXmBqFZPj69C/BpOzQZecq1P7AkKIu7esq+fe6ANKMinGJVQhrsrknwYVLznp8OfxIHzq6PLJADI8GZBBGq4hy4AsLbGZqt1jK8aDWoUrwSt+5QdQjMLxaljFNxonacmqoMa391V2vncN+npaQETI2nNxoXeLcPy0Yt0oPJccU9oYQh+fg52jSI3yXR8+fhDQyQLKVHHpYtH88wBSu4/fiwRWRAqRJYZg7AYAluEwNFePWnIH/UP1cUbiteWDKvwAoaaXKvGO5mBNi79G+Y42xv72RdHSIiBpvp4zuUCC5bt87k1QwjHeKGVhNMR2ba2Xz4AoJEw7VnCu8R8K6nif6LEr1kbIgmzM+LefnDggzONF5K7IGoMzjMfTJpdLDO3+MJiBsTW471HXgw2UzZKR2gpcHFkf3GcLsOcIOE9lqoDoFHvwpR8IhnK42qdV+m6VaXoWeSEjZEE99vqVNKyWHDAB4MZxNOrwIYSqnHExoNE8UixUYeL2F3Qv3Onjfg4sjDZVA+r0xjO97qm6IDk9NbWmna8E7vZGEh4GPTdHPwfFZHfJL3p8kFNh7AfZHSy1qrtXttw== a.khssnv@gmail.com"
  ];

}
