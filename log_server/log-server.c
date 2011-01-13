
#include <sys/types.h>
#include <sys/time.h>
#include <sys/queue.h>
#include <sys/types.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <netinet/in.h>
#include <net/if.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <time.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <assert.h>
#include <signal.h>
#include <stdbool.h>

#include <event2/event.h>
#include <event2/http.h>
#include <event2/buffer.h>
#include <event2/util.h>
#include <event2/keyvalq_struct.h>

#define VERSION "1"

/* 全局设置 */
FILE* g_logfd ; /*日誌文件句柄*/
char  g_dataname[1024];
char* g_pidfile; /* PID文件 */
char* g_listen = "0.0.0.0";
char* g_pidfile = "./log_server.pid";
char* g_datapath = "./data";
int   g_port = 1600;
int   g_syncinterval; /* 同步更新内容到磁盘的间隔时间 */
int   g_timeout = 3; /* 单位：秒 */
int   g_syncinterval = 5; /* 单位：秒 */
int   g_cur_wday = -1;//當前日期，周几
bool  g_daemon = false;


/* 创建多层目录的函数 */
void create_multilayer_dir( char *muldir )
{
    int    i,len;
    char    str[512];

    strncpy( str, muldir, 512 );
    len=strlen(str);
    for( i=0; i<len; i++ ){
        if( str[i]=='/' ){
            str[i] = '\0';
            //判断此目录是否存在,不存在则创建
            if( access(str, F_OK)!=0 ){
                mkdir( str, 0777 );
            }
            str[i]='/';
        }
    }
    if( len>0 && access(str, F_OK)!=0 ){
        mkdir( str, 0777 );
    }

    return;
}


static void show_help(void)
{
    char *b = "--------------------------------------------------------------------------------------------------\n"
        "HTTP Log Service - log_server v" VERSION " (, 2010)\n\n"
        "A web server just log  request\n"
        "\n"
        "-l <ip_addr>  interface to listen on, default is 0.0.0.0\n"
        "-p <num>      TCP port number to listen on (default: 1600)\n"
        "-x <path>     database directory (example: ./data)\n"
        "-t <second>   timeout for an http request (default: 3)\n"
        "-i <file>     save PID in <file> (default: ./log_server.pid)\n"
        "-d            run as a daemon\n"
        "-h            print this help and exit\n\n"
        "Use command \"killall log_server\", \"pkill log_server\" and \"kill `cat /tmp/log_server.pid`\" to stop log_server.\n"
        "Please note that don't use the command \"pkill -9 log_server\" and \"kill -9 PID of log_server\"!\n"
        "\n"
        "--------------------------------------------------------------------------------------------------\n"
        "\n";
    fprintf(stderr, b, strlen(b));
}


/* 修改定时更新内存内容到磁盘的间隔时间，返回间隔时间（秒） */
static int log_server_synctime(int log_server_input_num)
{
    if (log_server_input_num >= 1) {
        g_syncinterval = log_server_input_num;
    }
    return g_syncinterval;
}




/* 信号处理 */
static void kill_signal(/*const int sig*/) {
    /* 删除PID文件 */
    remove(g_pidfile);
    if(g_logfd){
        fflush(g_logfd);
        fclose(g_logfd);
    }
    exit(0);
}

/* 
 * 切換log file
 */
static void reopen_log_fd(struct tm *p)
{
    memset(g_dataname, '\0', sizeof(g_dataname));
    sprintf(g_dataname, "%s/log.%d-%02d-%02d", g_datapath,(1900+p->tm_year),(1+p->tm_mon),p->tm_mday);
    if(g_logfd){
        fflush(g_logfd);
        fclose(g_logfd);
        g_logfd=NULL;
    }
    g_logfd=fopen(g_dataname,"a+");
    if(NULL == g_logfd ){
        fprintf(stderr, "open file  for append error: %s\n",g_dataname);		
        perror("open file :");
        exit(1);
    }
}




static void log_handler(struct evhttp_request *req, void *arg)
{
    time_t timep;
    struct tm *p;
    time(&timep);
    p=localtime(&timep);
    if(p->tm_wday!= g_cur_wday){
        g_cur_wday=p->tm_wday;
        reopen_log_fd(p);
    }

    if(g_logfd!=NULL){
        struct evbuffer *buf;
        char cbuf[12800];
        int n;
        fprintf(g_logfd,"%s\t%d\t",evhttp_request_get_uri(req),timep);
        buf = evhttp_request_get_input_buffer(req);
        while (evbuffer_get_length(buf)) {
            n = evbuffer_remove(buf, cbuf, sizeof(buf)-1);
            fwrite(cbuf, 1, n, g_logfd);
        }
        cbuf[0]='\n';
        fwrite(cbuf, 1,1 , g_logfd);
        evhttp_send_reply(req, 200, "OK", NULL);
    }else
        evhttp_send_reply(req, 200, "KO", NULL);
}

/* 测试dump */
static void dump_request_cb(struct evhttp_request *req, void *arg)
{
    const char *cmdtype;
    struct evkeyvalq *headers;
    struct evkeyval *header;
    struct evbuffer *buf;

    switch (evhttp_request_get_command(req)) {
        case EVHTTP_REQ_GET: cmdtype = "GET"; break;
        case EVHTTP_REQ_POST: cmdtype = "POST"; break;
        case EVHTTP_REQ_HEAD: cmdtype = "HEAD"; break;
        case EVHTTP_REQ_PUT: cmdtype = "PUT"; break;
        case EVHTTP_REQ_DELETE: cmdtype = "DELETE"; break;
        case EVHTTP_REQ_OPTIONS: cmdtype = "OPTIONS"; break;
        case EVHTTP_REQ_TRACE: cmdtype = "TRACE"; break;
        case EVHTTP_REQ_CONNECT: cmdtype = "CONNECT"; break;
        case EVHTTP_REQ_PATCH: cmdtype = "PATCH"; break;
        default: cmdtype = "unknown"; break;
    }
    printf("Received a %s request for %s\nHeaders:\n",
            cmdtype, evhttp_request_get_uri(req));

    headers = evhttp_request_get_input_headers(req);
    for (header = headers->tqh_first; header;
            header = header->next.tqe_next) {
        printf("  %s: %s\n", header->key, header->value);
    }

    printf("remote_host: %s\n", evhttp_request_get_host(req));
    buf = evhttp_request_get_input_buffer(req);
    puts("Input data: <<<");
    while (evbuffer_get_length(buf)) {
        int n;
        char cbuf[128];
        n = evbuffer_remove(buf, cbuf, sizeof(buf)-1);
        fwrite(cbuf, 1, n, stdout);
    }
    puts(">>>");
    evhttp_send_reply(req, 200, "OK", NULL);
}

/* 定时信号处理，定时将内存中的内容写入磁盘 */
static void sync_signal(const int sig) {
    if(g_logfd){
        fflush(g_logfd);
    }
    alarm(g_syncinterval); //间隔g_syncinterval秒发一次信号
}


int main(int argc, char **argv)
{
    int c;
    /* 默认参数设置 */

    /* process arguments */
    while ((c = getopt(argc, argv, "l:p:x:t:s:c:m:i:dh")) != -1) {
        switch (c) {
            case 'l':
                g_listen = strdup(optarg);
                break;
            case 'p':
                g_port = atoi(optarg);
                break;
            case 'x':
                g_datapath = strdup(optarg); /* log_server数据库文件存放路径 */
                break;
            case 't':
                g_timeout = atoi(optarg);
                break;		
            case 's':
                g_syncinterval = atoi(optarg);
                break;			
            case 'i':
                g_pidfile = strdup(optarg);
                break;			
            case 'd':
                g_daemon = true;
                break;
            case 'h':
            default:
                show_help();
                return 1;
        }
    }

    /* 判断是否加了必填参数 -x */
    if (g_datapath == NULL) {
        show_help();
        fprintf(stderr, "Attention: Please use the  argument: -x <path>\n\n");		
        exit(1);
    }
    /* for mkdir */
    if (access(g_datapath, W_OK) != 0) { /* 如果目录不可写 */
        if (access(g_datapath, R_OK) == 0) { /* 如果目录可读 */
            chmod(g_datapath, S_IWOTH); /* 设置其他用户具可写入权限 */
        } else { /* 如果不存在该目录，则创建 */
            create_multilayer_dir(g_datapath);
        }

        if (access(g_datapath, W_OK) != 0) { /* 如果目录不可写 */
            fprintf(stderr, "log_server database directory not writable\n");
        }
    }




    /* 如果加了-d参数，以守护进程运行 */
    if (g_daemon == true){
        pid_t pid;

        /* Fork off the parent process */       
        pid = fork();
        if (pid < 0) {
            exit(EXIT_FAILURE);
        }
        /* If we got a good PID, then
           we can exit the parent process. */
        if (pid > 0) {
            exit(EXIT_SUCCESS);
        }
        /*
        close(0);
        close(1);
        close(2);
         */
    }

    time_t timep;
    struct tm *p;
    time(&timep);
    p=localtime(&timep);
    g_cur_wday=p->tm_wday;
    reopen_log_fd(p);
    if(NULL == g_logfd ){
        fprintf(stderr, "open file  for append error: %s\n",g_dataname);		
        perror("open file :");
        exit(1);
    }

    /* 将进程号写入PID文件 */
    FILE *fp_pidfile;
    fp_pidfile = fopen(g_pidfile, "w");
    fprintf(fp_pidfile, "%d\n", getpid());
    fclose(fp_pidfile);

    /* 忽略Broken Pipe信号 */
    signal(SIGPIPE, SIG_IGN);

    /* 处理kill信号 */
    signal (SIGINT, kill_signal);
    signal (SIGKILL, kill_signal);
    signal (SIGQUIT, kill_signal);
    signal (SIGTERM, kill_signal);
    signal (SIGHUP, kill_signal);

    /* 处理定时更新修改的数据到磁盘信号 */
    signal(SIGALRM, sync_signal);
    alarm(g_syncinterval); //间隔g_syncinterval秒发一次信号

    /* 请求处理部分 */
    struct event_base *base;
    struct evhttp *http;
    struct evhttp_bound_socket *handle;
    base = event_base_new();
    if (!base) {
        fprintf(stderr, "Couldn't create an event_base: exiting\n");
        return 1;
    }

    /* Create a new evhttp object to handle requests. */
    http = evhttp_new(base);
    if (!http) {
        fprintf(stderr, "couldn't create evhttp. Exiting.\n");
        return 1;
    }



    /* Now we tell the evhttp what port to listen on */
    handle = evhttp_bind_socket_with_handle(http, g_listen, g_port);
    if (handle == NULL) {
        fprintf(stderr, "Error: Unable to listen on %s:%d\n\n", g_listen, g_port);		
        exit(1);		
    }

    {
        /* Extract and display the address we're listening on. */
        struct sockaddr_storage ss;
        evutil_socket_t fd;
        ev_socklen_t socklen = sizeof(ss);
        char addrbuf[128];
        void *inaddr;
        const char *addr;
        int got_port = -1;
        fd = evhttp_bound_socket_get_fd(handle);
        memset(&ss, 0, sizeof(ss));
        if (getsockname(fd, (struct sockaddr *)&ss, &socklen)) {
            perror("getsockname() failed");
            return 1;
        }
        if (ss.ss_family == AF_INET) {
            got_port = ntohs(((struct sockaddr_in*)&ss)->sin_port);
            inaddr = &((struct sockaddr_in*)&ss)->sin_addr;
        } else if (ss.ss_family == AF_INET6) {
            got_port = ntohs(((struct sockaddr_in6*)&ss)->sin6_port);
            inaddr = &((struct sockaddr_in6*)&ss)->sin6_addr;
        } else {
            fprintf(stderr, "Weird address family %d\n",
                    ss.ss_family);
            return 1;
        }
        addr = evutil_inet_ntop(ss.ss_family, inaddr, addrbuf,
                sizeof(addrbuf));
        if (addr) {
            printf("Listening on %s:%d\n", addr, got_port);
            printf("http://%s:%d\n",addr,got_port);
        } else {
            fprintf(stderr, "evutil_inet_ntop failed\n");
            return 1;
        }
    }
	evhttp_set_cb(http, "/dump", dump_request_cb, NULL);
    /* We want to accept arbitrary requests, so we need to set a "generic"
     * cb.  We can also add callbacks for specific paths. */
    evhttp_set_gencb(http, log_handler, NULL);

    event_base_dispatch(base);

    /* Not reached in this code as it is now. */
    //evhttp_free(http);

    return 0;
}
