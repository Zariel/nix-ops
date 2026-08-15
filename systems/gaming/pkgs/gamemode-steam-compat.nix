{ pkgs }:

pkgs.gamemode.overrideAttrs (old: {
  pname = "${old.pname}-steam-compat";

  postFixup = (old.postFixup or "") + ''
    cat > gamemoderun-steam-compat.c <<'EOF'
    #define _POSIX_C_SOURCE 200809L

    #include <dlfcn.h>
    #include <errno.h>
    #include <signal.h>
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <sys/types.h>
    #include <sys/wait.h>
    #include <unistd.h>

    static const char *libgamemode_path = "${placeholder "lib"}/lib/libgamemode.so.0";
    static const char *shell_path = "${pkgs.stdenv.shell}";

    typedef int (*gamemode_request_fn)(void);
    typedef int (*gamemode_request_for_fn)(pid_t);
    typedef const char *(*gamemode_error_fn)(void);

    struct gamemode_api {
    	void *handle;
    	gamemode_request_fn request_start;
    	gamemode_request_fn request_end;
    	gamemode_request_for_fn request_start_for;
    	gamemode_request_for_fn request_end_for;
    	gamemode_error_fn error_string;
    };

    static void warn_gamemode(const struct gamemode_api *api, const char *context, int rc)
    {
    	const char *details = "unknown error";

    	if (api->error_string != NULL) {
    		const char *reported = api->error_string();
    		if (reported != NULL && reported[0] != '\0') {
    			details = reported;
    		}
    	}

    	fprintf(stderr, "gamemoderun: %s failed (%d): %s\n", context, rc, details);
    }

    static int bind_symbol(void *handle, const char *name, void **symbol)
    {
    	dlerror();
    	*symbol = dlsym(handle, name);
    	return *symbol == NULL && dlerror() != NULL ? -1 : 0;
    }

    static int load_gamemode_api(struct gamemode_api *api)
    {
    	memset(api, 0, sizeof(*api));

    	api->handle = dlopen(libgamemode_path, RTLD_NOW);
    	if (api->handle == NULL) {
    		fprintf(stderr, "gamemoderun: failed to load %s: %s\n", libgamemode_path, dlerror());
    		return -1;
    	}

    	if (bind_symbol(api->handle, "real_gamemode_error_string", (void **)&api->error_string) != 0) {
    		fprintf(stderr, "gamemoderun: missing GameMode error_string symbol\n");
    	}

    	if (bind_symbol(api->handle, "real_gamemode_request_start", (void **)&api->request_start) != 0) {
    		api->request_start = NULL;
    	}

    	if (bind_symbol(api->handle, "real_gamemode_request_end", (void **)&api->request_end) != 0) {
    		api->request_end = NULL;
    	}

    	if (bind_symbol(api->handle, "real_gamemode_request_start_for", (void **)&api->request_start_for) != 0) {
    		api->request_start_for = NULL;
    	}

    	if (bind_symbol(api->handle, "real_gamemode_request_end_for", (void **)&api->request_end_for) != 0) {
    		api->request_end_for = NULL;
    	}

    	return 0;
    }

    static int request_start(const struct gamemode_api *api, pid_t pid)
    {
    	int rc = -1;

    	if (api->request_start_for != NULL) {
    		rc = api->request_start_for(pid);
    		if (rc == 0) {
    			return 0;
    		}
    		warn_gamemode(api, "request_start_for", rc);
    	}

    	if (api->request_start != NULL) {
    		rc = api->request_start();
    		if (rc == 0) {
    			return 0;
    		}
    		warn_gamemode(api, "request_start", rc);
    	}

    	return rc;
    }

    static void request_end(const struct gamemode_api *api, pid_t pid)
    {
    	int rc = -1;

    	if (api->request_end_for != NULL) {
    		rc = api->request_end_for(pid);
    		if (rc == 0) {
    			return;
    		}
    		warn_gamemode(api, "request_end_for", rc);
    	}

    	if (api->request_end != NULL) {
    		rc = api->request_end();
    		if (rc != 0) {
    			warn_gamemode(api, "request_end", rc);
    		}
    	}
    }

    static void exec_target(int argc, char **argv)
    {
    	const char *wrapper = getenv("GAMEMODERUNEXEC");

    	if (wrapper != NULL && wrapper[0] != '\0') {
    		char **wrapper_argv = calloc((size_t)argc + 4, sizeof(char *));
    		int i;

    		if (wrapper_argv == NULL) {
    			perror("gamemoderun");
    			_exit(127);
    		}

    		wrapper_argv[0] = (char *)shell_path;
    		wrapper_argv[1] = (char *)"-c";
    		wrapper_argv[2] = (char *)"exec \"$GAMEMODERUNEXEC\" \"$@\"";
    		wrapper_argv[3] = (char *)"gamemoderun";

    		for (i = 1; i < argc; ++i) {
    			wrapper_argv[i + 3] = argv[i];
    		}

    		execv(shell_path, wrapper_argv);
    		perror(shell_path);
    		_exit(127);
    	}

    	execvp(argv[1], &argv[1]);
    	perror(argv[1]);
    	_exit(errno == ENOENT ? 127 : 126);
    }

    int main(int argc, char **argv)
    {
    	struct gamemode_api api;
    	int status = 0;
    	pid_t child;

    	if (argc < 2) {
    		fprintf(stderr, "usage: gamemoderun PROGRAM [ARGS...]\n");
    		return 1;
    	}

    	memset(&api, 0, sizeof(api));
    	(void)load_gamemode_api(&api);

    	child = fork();
    	if (child < 0) {
    		perror("fork");
    		if (api.handle != NULL) {
    			dlclose(api.handle);
    		}
    		return 1;
    	}

    	if (child == 0) {
    		exec_target(argc, argv);
    	}

    	if (api.handle != NULL) {
    		(void)request_start(&api, child);
    	}

    	while (waitpid(child, &status, 0) < 0) {
    		if (errno != EINTR) {
    			perror("waitpid");
    			if (api.handle != NULL) {
    				request_end(&api, child);
    				dlclose(api.handle);
    			}
    			return 1;
    		}
    	}

    	if (api.handle != NULL) {
    		request_end(&api, child);
    		dlclose(api.handle);
    	}

    	if (WIFEXITED(status)) {
    		return WEXITSTATUS(status);
    	}

    	if (WIFSIGNALED(status)) {
    		return 128 + WTERMSIG(status);
    	}

    	return 1;
    }
    EOF

    $CC \
      -O2 \
      -Wall \
      -Wextra \
      gamemoderun-steam-compat.c \
      -ldl \
      -o "$out/bin/gamemoderun"
  '';
})
