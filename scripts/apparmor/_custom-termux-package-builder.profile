#include <tunables/global>

/usr/bin/env {
  # Include standard abstractions
  #include <abstractions/base>
  #include <abstractions/nameservice>
  #include <abstractions/user-tmp>
  #include <abstractions/ssl>

  # Allow execution of the Termux build scripts
  /tmp/termux-packages/scripts/** mr,
  /tmp/termux-packages/build/** mr,
  /tmp/termux-packages/.git/** mr,
  /tmp/termux-packages/patches/** mr,

  # Allow access to system binaries for building
  /usr/bin/** mrx,
  /usr/lib/** mr,
  /usr/lib64/** mr,
  /usr/include/** r,
  /usr/local/bin/** mrx,

  # Allow temporary directories
  /tmp/** rw,
  /var/tmp/** rw,
  /dev/shm/** rw,

  # Allow reading /etc configuration files
  /etc/ld.so.cache r,
  /etc/ld.so.conf r,
  /etc/passwd r,
  /etc/group r,
  /etc/sudoers r,
  /etc/sudoers.d/** r,

  # AppArmor capabilities
  capability sys_admin,
  capability sys_chroot,
  capability sys_ptrace,
  capability sys_boot,
  capability sys_module,
  capability sys_nice,
  capability sys_time,
  capability syslog,
  capability dac_read_search,
  capability sys_rawio,
  capability sys_tty_config,

  # Allow common build syscalls
  network inet stream,
  network inet dgram,
  network inet6 stream,
  network inet6 dgram,

  # Allow file operations needed for packaging
  /dev/null rw,
  /dev/urandom r,
  /proc/mounts r,
  /proc/sys/kernel/hostname r,
  /proc/sys/kernel/domainname r,
  /proc/sys/kernel/osrelease r,
  /proc/sys/kernel/version r,
  /proc/sys/kernel/random/uuid r,
  /proc/cpuinfo r,
  /proc/meminfo r,
  /proc/stat r,
  /proc/loadavg r,
  /proc/uptime r,
  /proc/self/** r,
  /proc/sys/** r,
  /sys/devices/** r,
  /sys/class/** r,
  /sys/block/** r,

  # Mounts for building packages (chrooted)
  mount,
  umount2,

  # Standard read/write for building
  file,
  link,
  unlink,
  rename,
  mkdir,
  rmdir,
  symlink,
  chmod,
  chown,
  utimens,

  # Execution permissions
  /bin/** mrx,
  /usr/bin/** mrx,
  /usr/local/bin/** mrx,

  # Allow compiler and linker usage
  /usr/lib/gcc/** mr,
  /usr/lib/ld-linux* r,
  /usr/libexec/gcc/** mr,
  /usr/bin/ld mrx,
  /usr/bin/as mrx,
  /usr/bin/gcc mrx,
  /usr/bin/cc mrx,
  /usr/bin/make mrx,
  /usr/bin/makeinfo mrx,
  /usr/bin/python3 mrx,

  # Allow writing logs
  /var/log/** w,
  /var/lib/** w,

  # Allow user home for temporary builds
  /home/builder/** rw,

  # Deny everything else by default
  deny /** rwklx,

  # Syscalls explicitly allowed
  /usr/bin/env {
    # Standard syscalls
    personality,
    clone,
    fork,
    vfork,
    execve,
    execveat,
    exit,
    exit_group,
    kill,
    wait4,
    waitid,
    open,
    openat,
    creat,
    read,
    write,
    pread64,
    pwrite64,
    readv,
    writev,
    lseek,
    close,
    fstat,
    fstat64,
    fcntl,
    fcntl64,
    ioctl,
    dup,
    dup2,
    dup3,
    pipe,
    pipe2,
    select,
    pselect6,
    poll,
    ppoll,
    epoll_create,
    epoll_create1,
    epoll_ctl,
    epoll_wait,
    epoll_pwait,
    epoll_pwait2,
    eventfd,
    eventfd2,
    inotify_init,
    inotify_init1,
    inotify_add_watch,
    inotify_rm_watch,
    nanosleep,
    clock_nanosleep,
    futex,
    futex_waitv,
    getpid,
    getppid,
    getuid,
    geteuid,
    getgid,
    getegid,
    getresuid,
    getresgid,
    setresuid,
    setresgid,
    setuid,
    setgid,
    setgroups,
    setrlimit,
    getrlimit,
    prctl,
    arch_prctl,
    mprotect,
    mlock,
    munlock,
    mmap,
    munmap,
    mremap,
    madvise,
    mincore,
    brk,
    sbrk,
    ptrace,
    process_vm_readv,
    process_vm_writev
  }
}